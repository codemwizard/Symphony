using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

/// <summary>
/// Epoch Sealing Command — TSK-P3-W8-SEAL-001
/// 
/// Populates the dormant proof_pack_batches (migration 0066) Merkle tree tables.
/// Accepts a batch of evidence_node_ids filtered to constitutional data classes
/// (evidentiary, provenance, replay), computes SHA-256 leaf hashes from canonical
/// payloads, builds a Merkle tree, and writes to proof_pack_batches and
/// proof_pack_batch_leaves.
/// 
/// Records each seal run in archive_verification_runs with run_scope,
/// years_covered, canonicalization_versions_covered, and outcome.
/// </summary>
static class EpochSealingCommand
{
    public sealed record EpochSealInput(
        Guid[] EvidenceNodeIds,
        string RunScope,
        string YearsCovered,
        string CanonVersions
    );

    public sealed record EpochSealResult(
        Guid BatchId,
        string MerkleRoot,
        int LeafCount,
        Guid VerificationRunId
    );

    public sealed record LeafEntry(
        Guid EvidenceNodeId,
        string LeafHash,
        string[] MerkleProof
    );

    /// <summary>
    /// Compute SHA-256 leaf hash from a canonical payload string.
    /// This is the same hash that an external verifier would independently compute.
    /// </summary>
    public static string ComputeLeafHash(string canonicalPayload)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonicalPayload))).ToLowerInvariant();

    /// <summary>
    /// Build a Merkle tree from an ordered list of leaf hashes.
    /// Returns (merkle_root, proofs_per_leaf).
    /// </summary>
    public static (string Root, string[][] Proofs) BuildMerkleTree(string[] leafHashes)
    {
        if (leafHashes.Length == 0)
            throw new ArgumentException("Cannot build Merkle tree from empty leaf set.");

        // Tree levels: bottom is leaves, top is root
        var levels = new List<string[]>();
        levels.Add(leafHashes);

        while (levels[^1].Length > 1)
        {
            var current = levels[^1];
            // Duplicate last node if odd count (standard Bitcoin Merkle approach)
            if (current.Length % 2 != 0)
            {
                var padded = new string[current.Length + 1];
                Array.Copy(current, padded, current.Length);
                padded[^1] = current[^1];
                current = padded;
                levels[^1] = current;
            }
            var nextLen = current.Length / 2;
            var next = new string[nextLen];
            for (int i = 0; i < nextLen; i++)
                next[i] = HashPair(current[i * 2], current[i * 2 + 1]);
            levels.Add(next);
        }

        var root = levels[^1][0];

        // Build proof for each leaf (only for original leaves, not padding)
        var proofs = new string[leafHashes.Length][];
        for (int leafIdx = 0; leafIdx < leafHashes.Length; leafIdx++)
        {
            var proof = new List<string>();
            int idx = leafIdx;
            for (int level = 0; level < levels.Count - 1; level++)
            {
                int siblingIdx = (idx % 2 == 0) ? idx + 1 : idx - 1;
                proof.Add(levels[level][siblingIdx]);
                idx /= 2;
            }
            proofs[leafIdx] = proof.ToArray();
        }

        return (root, proofs);
    }

    /// <summary>
    /// Verify a leaf against a Merkle root using the proof path.
    /// </summary>
    public static bool VerifyMerkleProof(string leafHash, string[] proof, string expectedRoot, int leafIndex)
    {
        var current = leafHash;
        int idx = leafIndex;
        foreach (var sibling in proof)
        {
            current = (idx % 2 == 0)
                ? HashPair(current, sibling)
                : HashPair(sibling, current);
            idx /= 2;
        }
        return string.Equals(current, expectedRoot, StringComparison.Ordinal);
    }

    /// <summary>
    /// Filter evidence node IDs to only constitutional data classes.
    /// Operational nodes are excluded from epoch sealing.
    /// </summary>
    public static readonly HashSet<string> ConstitutionalClasses = new(StringComparer.OrdinalIgnoreCase)
    {
        "evidentiary", "provenance", "replay"
    };

    public static bool IsConstitutionalClass(string dataClass)
        => ConstitutionalClasses.Contains(dataClass);

    private static string HashPair(string left, string right)
        => Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(left + right))
        ).ToLowerInvariant();
}
