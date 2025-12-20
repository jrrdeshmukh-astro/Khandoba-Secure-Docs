using Xunit;
using FluentAssertions;
using KhandobaSecureDocs.Services;

namespace KhandobaSecureDocs.Tests.Services
{
    public class EncryptionServiceTests
    {
        private readonly EncryptionService _encryptionService;

        public EncryptionServiceTests()
        {
            _encryptionService = new EncryptionService();
        }

        [Fact]
        public async Task EncryptAndDecrypt_ShouldRoundTripCorrectly()
        {
            // Arrange
            var originalData = System.Text.Encoding.UTF8.GetBytes("Test data to encrypt");
            var key = await _encryptionService.GenerateEncryptionKeyAsync();

            // Act
            var encryptedData = await _encryptionService.EncryptAES256GCMAsync(originalData, key);
            var decryptedData = await _encryptionService.DecryptAES256GCMAsync(encryptedData, key);

            // Assert
            encryptedData.Should().NotBeNull();
            encryptedData.Should().NotBeEquivalentTo(originalData, "Encrypted data should differ from original");
            decryptedData.Should().BeEquivalentTo(originalData, "Decrypted data should match original");
        }

        [Fact]
        public async Task Encrypt_WithDifferentKeys_ShouldProduceDifferentResults()
        {
            // Arrange
            var originalData = System.Text.Encoding.UTF8.GetBytes("Test data");
            var key1 = await _encryptionService.GenerateEncryptionKeyAsync();
            var key2 = await _encryptionService.GenerateEncryptionKeyAsync();

            // Act
            var encrypted1 = await _encryptionService.EncryptAES256GCMAsync(originalData, key1);
            var encrypted2 = await _encryptionService.EncryptAES256GCMAsync(originalData, key2);

            // Assert
            encrypted1.Should().NotBeEquivalentTo(encrypted2, "Different keys should produce different encrypted data");
        }

        [Fact]
        public async Task Decrypt_WithWrongKey_ShouldThrowException()
        {
            // Arrange
            var originalData = System.Text.Encoding.UTF8.GetBytes("Test data");
            var correctKey = await _encryptionService.GenerateEncryptionKeyAsync();
            var wrongKey = await _encryptionService.GenerateEncryptionKeyAsync();

            var encryptedData = await _encryptionService.EncryptAES256GCMAsync(originalData, correctKey);

            // Act & Assert
            await Assert.ThrowsAsync<Exception>(async () =>
            {
                await _encryptionService.DecryptAES256GCMAsync(encryptedData, wrongKey);
            });
        }

        [Fact]
        public async Task GenerateEncryptionKey_ShouldReturnUniqueKeys()
        {
            // Act
            var key1 = await _encryptionService.GenerateEncryptionKeyAsync();
            var key2 = await _encryptionService.GenerateEncryptionKeyAsync();

            // Assert
            key1.Should().NotBeNull();
            key2.Should().NotBeNull();
            key1.Should().NotBeEquivalentTo(key2, "Keys should be unique");
        }
    }
}
