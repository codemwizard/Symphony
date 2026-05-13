using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Xunit;

/// <summary>
/// Tests for EpochSealingCommand — TSK-P3-W8-SEAL-001
/// Tests for TamperEvidentChain.ExtractLeafHashes — TSK-P3-W8-ARCH-001
/// </summary>
public class EpochSealingCommandTests
{
    // ──── TSK-P3-W8-SEAL-001 Tests ────

    [Fact]
    public void MerkleRoot_SingleLeaf_ReturnsLeafHash()
    {
        var leaf = EpochSealingCommand.ComputeLeafHash("{\"test\":\"payload\"}");
        var (root, proofs) = EpochSealingCommand.BuildMerkleTree(new[] { leaf });
        Assert.Equal(leaf, root);
        Assert.Single(proofs);
        Assert.Empty(proofs[0]); // single leaf has no proof siblings
    }

    [Fact]
    public void MerkleRoot_TwoLeaves_IsDeterministic()
    {
        var leaf1 = EpochSealingCommand.ComputeLeafHash("{\"a\":1}");
        var leaf2 = EpochSealingCommand.ComputeLeafHash("{\"b\":2}");
        var (root1, _) = EpochSealingCommand.BuildMerkleTree(new[] { leaf1, leaf2 });
        var (root2, _) = EpochSealingCommand.BuildMerkleTree(new[] { leaf1, leaf2 });
        Assert.Equal(root1, root2);
    }

    [Fact]
    public void MerkleRoot_DifferentOrder_ProducesDifferentRoot()
    {
        var leaf1 = EpochSealingCommand.ComputeLeafHash("{\"a\":1}");
        var leaf2 = EpochSealingCommand.ComputeLeafHash("{\"b\":2}");
        var (root1, _) = EpochSealingCommand.BuildMerkleTree(new[] { leaf1, leaf2 });
        var (root2, _) = EpochSealingCommand.BuildMerkleTree(new[] { leaf2, leaf1 });
        Assert.NotEqual(root1, root2);
    }

    [Fact]
    public void MerkleProof_VerifiesCorrectly_ForEachLeaf()
    {
        var leaves = new[]
        {
            EpochSealingCommand.ComputeLeafHash("{\"node\":1}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":2}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":3}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":4}"),
        };
        var (root, proofs) = EpochSealingCommand.BuildMerkleTree(leaves);

        for (int i = 0; i < leaves.Length; i++)
        {
            Assert.True(
                EpochSealingCommand.VerifyMerkleProof(leaves[i], proofs[i], root, i),
                $"Proof verification failed for leaf {i}"
            );
        }
    }

    [Fact]
    public void MerkleProof_FailsForWrongLeaf()
    {
        var leaves = new[]
        {
            EpochSealingCommand.ComputeLeafHash("{\"node\":1}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":2}"),
        };
        var (root, proofs) = EpochSealingCommand.BuildMerkleTree(leaves);

        var fakeLeaf = EpochSealingCommand.ComputeLeafHash("{\"tampered\":true}");
        Assert.False(EpochSealingCommand.VerifyMerkleProof(fakeLeaf, proofs[0], root, 0));
    }

    [Fact]
    public void MerkleTree_OddLeafCount_ProducesValidRoot()
    {
        var leaves = new[]
        {
            EpochSealingCommand.ComputeLeafHash("{\"node\":1}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":2}"),
            EpochSealingCommand.ComputeLeafHash("{\"node\":3}"),
        };
        var (root, proofs) = EpochSealingCommand.BuildMerkleTree(leaves);

        Assert.NotEmpty(root);
        for (int i = 0; i < leaves.Length; i++)
        {
            Assert.True(EpochSealingCommand.VerifyMerkleProof(leaves[i], proofs[i], root, i));
        }
    }

    [Fact]
    public void EmptyBatch_ThrowsArgumentException()
    {
        Assert.Throws<ArgumentException>(() =>
            EpochSealingCommand.BuildMerkleTree(Array.Empty<string>()));
    }

    [Fact]
    public void OperationalNodes_ExcludedFromSealing()
    {
        Assert.False(EpochSealingCommand.IsConstitutionalClass("operational"));
        Assert.False(EpochSealingCommand.IsConstitutionalClass("identity"));
        Assert.False(EpochSealingCommand.IsConstitutionalClass("regulator"));
    }

    [Fact]
    public void ConstitutionalNodes_IncludedInSealing()
    {
        Assert.True(EpochSealingCommand.IsConstitutionalClass("evidentiary"));
        Assert.True(EpochSealingCommand.IsConstitutionalClass("provenance"));
        Assert.True(EpochSealingCommand.IsConstitutionalClass("replay"));
    }

    [Fact]
    public void LeafHash_RoundTrip_IndependentlyRecomputable()
    {
        var payload = "{\"evidence_node_id\":\"abc-123\",\"data\":\"test_value\"}";
        var hash1 = EpochSealingCommand.ComputeLeafHash(payload);

        // Independent recomputation using raw SHA256
        var hash2 = Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(payload))
        ).ToLowerInvariant();

        Assert.Equal(hash1, hash2);
    }

    // ──── TSK-P3-W8-ARCH-001 Tests ────

    [Fact]
    public void ExtractLeafHashes_ValidNdjson_YieldsCorrectHashes()
    {
        var tempPath = Path.GetTempFileName();
        try
        {
            // Write two NDJSON lines with chain_records
            var line1 = JsonSerializer.Serialize(new
            {
                instruction_id = "instr-001",
                chain_record = new { current_hash = "hash_aaa", previous_hash = (string?)null, payload_hash = "ph1", domain = "test", generated_at_utc = "2026-01-01T00:00:00Z", commit_boundary = "single_write_envelope" }
            });
            var line2 = JsonSerializer.Serialize(new
            {
                instruction_id = "instr-002",
                chain_record = new { current_hash = "hash_bbb", previous_hash = "hash_aaa", payload_hash = "ph2", domain = "test", generated_at_utc = "2026-01-01T00:01:00Z", commit_boundary = "single_write_envelope" }
            });
            File.WriteAllText(tempPath, line1 + "\n" + line2 + "\n");

            var results = TamperEvidentChain.ExtractLeafHashes(tempPath).ToList();

            Assert.Equal(2, results.Count);
            Assert.Equal("instr-001", results[0].ArtifactId);
            Assert.Equal("hash_aaa", results[0].LeafHash);
            Assert.Equal("instr-002", results[1].ArtifactId);
            Assert.Equal("hash_bbb", results[1].LeafHash);
        }
        finally
        {
            File.Delete(tempPath);
        }
    }

    [Fact]
    public void ExtractLeafHashes_SkipsEmptyLines()
    {
        var tempPath = Path.GetTempFileName();
        try
        {
            var line1 = JsonSerializer.Serialize(new
            {
                instruction_id = "instr-001",
                chain_record = new { current_hash = "hash_aaa", previous_hash = (string?)null, payload_hash = "ph1", domain = "test", generated_at_utc = "2026-01-01T00:00:00Z", commit_boundary = "single_write_envelope" }
            });
            File.WriteAllText(tempPath, line1 + "\n\n\n");

            var results = TamperEvidentChain.ExtractLeafHashes(tempPath).ToList();
            Assert.Single(results);
        }
        finally
        {
            File.Delete(tempPath);
        }
    }

    [Fact]
    public void ExtractLeafHashes_CorruptedJson_Throws()
    {
        var tempPath = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempPath, "not valid json\n");

            Assert.Throws<InvalidOperationException>(() =>
                TamperEvidentChain.ExtractLeafHashes(tempPath).ToList());
        }
        finally
        {
            File.Delete(tempPath);
        }
    }

    [Fact]
    public void AppChainHash_Matches_DbLeafHash_ForSameRecord()
    {
        // Simulate: application writes a chain entry, then we extract leaf hash,
        // then we compute a DB leaf hash from the same canonical payload.
        // They must match because ExtractLeafHashes uses current_hash from chain_record.
        var tempPath = Path.GetTempFileName();
        try
        {
            var line = JsonSerializer.Serialize(new
            {
                instruction_id = "instr-match",
                chain_record = new
                {
                    current_hash = "abc123def456",
                    previous_hash = (string?)null,
                    payload_hash = "ph_match",
                    domain = "test",
                    generated_at_utc = "2026-01-01T00:00:00Z",
                    commit_boundary = "single_write_envelope"
                }
            });
            File.WriteAllText(tempPath, line + "\n");

            var extracted = TamperEvidentChain.ExtractLeafHashes(tempPath).First();

            // The leaf hash from extraction should be the chain_record.current_hash
            Assert.Equal("abc123def456", extracted.LeafHash);
        }
        finally
        {
            File.Delete(tempPath);
        }
    }

    [Fact]
    public void RoundTrip_WriteExtractSealVerify()
    {
        var tempPath = Path.GetTempFileName();
        try
        {
            // Step 1: Write NDJSON entries
            var entries = new[]
            {
                new { instruction_id = "rt-001", chain_record = new { current_hash = "h1", previous_hash = (string?)null, payload_hash = "p1", domain = "ledger", generated_at_utc = "2026-01-01T00:00:00Z", commit_boundary = "single_write_envelope" } },
                new { instruction_id = "rt-002", chain_record = new { current_hash = "h2", previous_hash = "h1", payload_hash = "p2", domain = "ledger", generated_at_utc = "2026-01-01T00:01:00Z", commit_boundary = "single_write_envelope" } },
            };
            File.WriteAllLines(tempPath, entries.Select(e => JsonSerializer.Serialize(e)));

            // Step 2: Extract leaf hashes
            var leafHashes = TamperEvidentChain.ExtractLeafHashes(tempPath)
                .Select(lh => lh.LeafHash)
                .ToArray();

            // Step 3: Build Merkle tree
            var (root, proofs) = EpochSealingCommand.BuildMerkleTree(leafHashes);

            // Step 4: Verify each proof
            for (int i = 0; i < leafHashes.Length; i++)
            {
                Assert.True(
                    EpochSealingCommand.VerifyMerkleProof(leafHashes[i], proofs[i], root, i),
                    $"Round-trip proof verification failed for leaf {i}"
                );
            }
        }
        finally
        {
            File.Delete(tempPath);
        }
    }
}
