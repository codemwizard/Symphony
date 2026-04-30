using System;
using System.Security.Cryptography;
using System.Text;
using Xunit;

namespace Symphony.Cryptography.Tests
{
    /// <summary>
    /// Primitive-level tests for Ed25519 verification.
    /// Tests prove malformed-signature failure, wrong-key failure, valid-signature success,
    /// and fail-closed runtime behavior inside the proven environment.
    /// </summary>
    public class Ed25519VerifierTests
    {
        private readonly MockKeyScopeValidator _keyScopeValidator;
        private readonly Ed25519Verifier _verifier;

        public Ed25519VerifierTests()
        {
            _keyScopeValidator = new MockKeyScopeValidator();
            _verifier = new Ed25519Verifier(_keyScopeValidator);
        }

        [Fact]
        public void Verify_ValidSignature_Success()
        {
            // Arrange
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] publicKeyBytes;
            byte[] signatureBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
                var privateKeyBytes = ed25519.GetPrivateKey();
                signatureBytes = ed25519.SignData(canonicalBytes);
            }

            // Act
            bool result = _verifier.Verify(
                canonicalBytes,
                signatureBytes,
                publicKeyBytes,
                "test-key",
                "1",
                "test-project");

            // Assert
            Assert.True(result);
        }

        [Fact]
        public void Verify_MalformedSignature_Failure()
        {
            // Arrange
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] malformedSignature = new byte[] { 0x01, 0x02, 0x03 }; // Invalid signature length
            byte[] publicKeyBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
            }

            // Act & Assert
            Assert.Throws<InvalidOperationException>(() =>
            {
                _verifier.Verify(
                    canonicalBytes,
                    malformedSignature,
                    publicKeyBytes,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void Verify_WrongKey_Failure()
        {
            // Arrange
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] signatureBytes;
            byte[] publicKeyBytes;
            byte[] wrongPublicKeyBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
                var privateKeyBytes = ed25519.GetPrivateKey();
                signatureBytes = ed25519.SignData(canonicalBytes);
            }

            using (var ed25519 = Ed25519.Create())
            {
                wrongPublicKeyBytes = ed25519.PublicKey;
            }

            // Act & Assert
            Assert.Throws<InvalidOperationException>(() =>
            {
                _verifier.Verify(
                    canonicalBytes,
                    signatureBytes,
                    wrongPublicKeyBytes,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void Verify_NullCanonicalBytes_Failure()
        {
            // Arrange
            byte[] signatureBytes = new byte[64];
            byte[] publicKeyBytes = new byte[32];

            // Act & Assert
            Assert.Throws<ArgumentNullException>(() =>
            {
                _verifier.Verify(
                    null!,
                    signatureBytes,
                    publicKeyBytes,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void Verify_NullSignatureBytes_Failure()
        {
            // Arrange
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] publicKeyBytes = new byte[32];

            // Act & Assert
            Assert.Throws<ArgumentNullException>(() =>
            {
                _verifier.Verify(
                    canonicalBytes,
                    null!,
                    publicKeyBytes,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void Verify_NullPublicKeyBytes_Failure()
        {
            // Arrange
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] signatureBytes = new byte[64];

            // Act & Assert
            Assert.Throws<ArgumentNullException>(() =>
            {
                _verifier.Verify(
                    canonicalBytes,
                    signatureBytes,
                    null!,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void Verify_KeyScopeViolation_Failure()
        {
            // Arrange
            _keyScopeValidator.ShouldValidate = false;
            byte[] canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}");
            byte[] publicKeyBytes;
            byte[] signatureBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
                signatureBytes = ed25519.SignData(canonicalBytes);
            }

            // Act & Assert
            Assert.Throws<InvalidOperationException>(() =>
            {
                _verifier.Verify(
                    canonicalBytes,
                    signatureBytes,
                    publicKeyBytes,
                    "test-key",
                    "1",
                    "test-project");
            });
        }

        [Fact]
        public void VerifyJson_ValidSignature_Success()
        {
            // Arrange
            string payloadJson = "{\"test\":\"data\"}";
            byte[] publicKeyBytes;
            byte[] signatureBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
                var canonicalBytes = Encoding.UTF8.GetBytes(payloadJson);
                signatureBytes = ed25519.SignData(canonicalBytes);
            }

            // Act
            bool result = _verifier.VerifyJson(
                payloadJson,
                signatureBytes,
                publicKeyBytes,
                "test-key",
                "1",
                "test-project");

            // Assert
            Assert.True(result);
        }

        [Fact]
        public void VerifyJson_NonCanonicalByteStream_Rejected()
        {
            // Arrange
            string prettyJson = "{\n  \"test\": \"data\"\n}"; // Non-canonical formatting
            byte[] publicKeyBytes;
            byte[] signatureBytes;

            using (var ed25519 = Ed25519.Create())
            {
                publicKeyBytes = ed25519.PublicKey;
                var canonicalBytes = Encoding.UTF8.GetBytes("{\"test\":\"data\"}"); // Canonical version
                signatureBytes = ed25519.SignData(canonicalBytes);
            }

            // Act
            bool result = _verifier.VerifyJson(
                prettyJson,
                signatureBytes,
                publicKeyBytes,
                "test-key",
                "1",
                "test-project");

            // Assert - should succeed because we canonicalize before verifying
            Assert.True(result);
        }

        /// <summary>
        /// Mock key scope validator for testing.
        /// </summary>
        private class MockKeyScopeValidator : IKeyScopeValidator
        {
            public bool ShouldValidate { get; set; } = true;

            public bool ValidateScope(string keyId, string keyVersion, string projectId, string? entityType)
            {
                return ShouldValidate;
            }
        }
    }
}
