using Xunit;
using FluentAssertions;
using Moq;
using KhandobaSecureDocs.Services;
using KhandobaSecureDocs.Models;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Tests.Services
{
    public class VaultServiceTests
    {
        private readonly Mock<SupabaseService> _mockSupabaseService;
        private readonly VaultService _vaultService;

        public VaultServiceTests()
        {
            _mockSupabaseService = new Mock<SupabaseService>();
            _vaultService = new VaultService(_mockSupabaseService.Object);
        }

        [Fact]
        public async Task CreateVault_ShouldCallSupabaseService()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var vaultName = "Test Vault";
            var vaultDescription = "Test Description";

            var expectedVault = new Vault
            {
                Id = Guid.NewGuid(),
                Name = vaultName,
                Description = vaultDescription,
                OwnerID = userId
            };

            _mockSupabaseService
                .Setup(x => x.InsertAsync(It.IsAny<string>(), It.IsAny<object>()))
                .ReturnsAsync(expectedVault);

            // Act
            var result = await _vaultService.CreateVaultAsync(userId, vaultName, vaultDescription, "single");

            // Assert
            result.Should().NotBeNull();
            result.Name.Should().Be(vaultName);
            _mockSupabaseService.Verify(x => x.InsertAsync("vaults", It.IsAny<object>()), Times.Once);
        }

        [Fact]
        public async Task GetVaultsByOwner_ShouldReturnVaults()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var vaults = new List<Vault>
            {
                new Vault { Id = Guid.NewGuid(), Name = "Vault 1", OwnerID = userId },
                new Vault { Id = Guid.NewGuid(), Name = "Vault 2", OwnerID = userId }
            };

            _mockSupabaseService
                .Setup(x => x.FetchAsync<List<Vault>>(It.IsAny<string>(), It.IsAny<Dictionary<string, object>>()))
                .ReturnsAsync(vaults);

            // Act
            var result = await _vaultService.GetVaultsByOwnerAsync(userId);

            // Assert
            result.Should().NotBeNull();
            result.Should().HaveCount(2);
        }
    }
}
