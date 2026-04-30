using System;
using System.Security.Cryptography;
using System.Text.Json;

namespace Symphony.Cryptography
{
    /// <summary>
    /// Ed25519 verification primitive for Wave 8.
    /// Verifies signatures over contract-defined canonical bytes (RFC 8785).
    /// Rejects non-canonical byte interpretations.
    /// </summary>
    public class Ed25519Verifier
    {
        private readonly IKeyScopeValidator _keyScopeValidator;

        public Ed25519Verifier(IKeyScopeValidator keyScopeValidator)
        {
            _keyScopeValidator = keyScopeValidator ?? throw new ArgumentNullException(nameof(keyScopeValidator));
        }

        /// <summary>
        /// Verifies an Ed25519 signature over canonical payload bytes.
        /// </summary>
        /// <param name="canonicalPayloadBytes">Canonical UTF-8 bytes (RFC 8785)</param>
        /// <param name="signatureBytes">Signature bytes (base64url without padding)</param>
        /// <param name="publicKeyBytes">Public key bytes</param>
        /// <param name="keyId">Key identifier for scope validation</param>
        /// <param name="keyVersion">Key version for scope validation</param>
        /// <param name="projectId">Project ID for scope validation</param>
        /// <param name="entityType">Entity type for scope validation (optional)</param>
        /// <returns>True if verification succeeds, false otherwise</returns>
        /// <exception cref="ArgumentNullException">Thrown when required parameters are null</exception>
        /// <exception cref="InvalidOperationException">Thrown when verification fails</exception>
        public bool Verify(
            byte[] canonicalPayloadBytes,
            byte[] signatureBytes,
            byte[] publicKeyBytes,
            string keyId,
            string keyVersion,
            string projectId,
            string? entityType = null)
        {
            // Validate inputs
            if (canonicalPayloadBytes == null || canonicalPayloadBytes.Length == 0)
                throw new ArgumentNullException(nameof(canonicalPayloadBytes), "Canonical payload bytes are required");
            
            if (signatureBytes == null || signatureBytes.Length == 0)
                throw new ArgumentNullException(nameof(signatureBytes), "Signature bytes are required");
            
            if (publicKeyBytes == null || publicKeyBytes.Length == 0)
                throw new ArgumentNullException(nameof(publicKeyBytes), "Public key bytes are required");
            
            if (string.IsNullOrEmpty(keyId))
                throw new ArgumentNullException(nameof(keyId), "Key ID is required");
            
            if (string.IsNullOrEmpty(keyVersion))
                throw new ArgumentNullException(nameof(keyVersion), "Key version is required");
            
            if (string.IsNullOrEmpty(projectId))
                throw new ArgumentNullException(nameof(projectId), "Project ID is required");

            // Validate key scope
            if (!_keyScopeValidator.ValidateScope(keyId, keyVersion, projectId, entityType))
            {
                throw new InvalidOperationException($"Key scope validation failed for key {keyId}:{keyVersion}");
            }

            // Verify Ed25519 signature using first-party surface
            using var ed25519 = Ed25519.ImportPublicKey(publicKeyBytes);
            bool isValid = ed25519.Verify(signatureBytes, canonicalPayloadBytes);

            if (!isValid)
            {
                throw new InvalidOperationException("Ed25519 signature verification failed");
            }

            return true;
        }

        /// <summary>
        /// Verifies an Ed25519 signature over a JSON payload.
        /// The payload is canonicalized using RFC 8785 before verification.
        /// </summary>
        /// <param name="payloadJson">JSON payload to canonicalize and verify</param>
        /// <param name="signatureBytes">Signature bytes (base64url without padding)</param>
        /// <param name="publicKeyBytes">Public key bytes</param>
        /// <param name="keyId">Key identifier for scope validation</param>
        /// <param name="keyVersion">Key version for scope validation</param>
        /// <param name="projectId">Project ID for scope validation</param>
        /// <param name="entityType">Entity type for scope validation (optional)</param>
        /// <returns>True if verification succeeds, false otherwise</returns>
        public bool VerifyJson(
            string payloadJson,
            byte[] signatureBytes,
            byte[] publicKeyBytes,
            string keyId,
            string keyVersion,
            string projectId,
            string? entityType = null)
        {
            if (string.IsNullOrEmpty(payloadJson))
                throw new ArgumentNullException(nameof(payloadJson), "Payload JSON is required");

            // Canonicalize using RFC 8785
            byte[] canonicalBytes = CanonicalizeRfc8785(payloadJson);

            // Verify over canonical bytes
            return Verify(canonicalBytes, signatureBytes, publicKeyBytes, keyId, keyVersion, projectId, entityType);
        }

        /// <summary>
        /// Canonicalizes JSON using RFC 8785 (JSON Canonicalization Scheme).
        /// </summary>
        /// <param name="json">JSON string to canonicalize</param>
        /// <returns>Canonical UTF-8 bytes</returns>
        private byte[] CanonicalizeRfc8785(string json)
        {
            // Parse JSON to ensure it's valid
            using var document = JsonDocument.Parse(json);
            
            // Serialize with canonical options (RFC 8785)
            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };

            string canonicalJson = JsonSerializer.Serialize(document.RootElement, options);
            return Encoding.UTF8.GetBytes(canonicalJson);
        }
    }

    /// <summary>
    /// Interface for key scope validation.
    /// </summary>
    public interface IKeyScopeValidator
    {
        /// <summary>
        /// Validates that a key is authorized for the given scope.
        /// </summary>
        /// <param name="keyId">Key identifier</param>
        /// <param name="keyVersion">Key version</param>
        /// <param name="projectId">Project ID</param>
        /// <param name="entityType">Entity type (optional)</param>
        /// <returns>True if the key is authorized for the scope</returns>
        bool ValidateScope(string keyId, string keyVersion, string projectId, string? entityType);
    }
}
