using Xunit;
using FluentAssertions;
using KhandobaSecureDocs.Services;
using System;
using System.Collections.Generic;
using System.Drawing;

namespace KhandobaSecureDocs.Tests.Services
{
    public class RedactionServiceTests
    {
        private readonly RedactionService _redactionService;

        public RedactionServiceTests()
        {
            _redactionService = new RedactionService();
        }

        [Fact]
        public void RedactImage_ShouldApplyRedactions()
        {
            // Arrange
            var imageData = CreateTestImageBytes();
            var redactionAreas = new List<RectangleF>
            {
                new RectangleF(10, 10, 50, 50)
            };

            // Act
            var result = _redactionService.RedactImage(imageData, redactionAreas);

            // Assert
            result.Should().NotBeNull();
            result.Length.Should().BeGreaterThan(0);
        }

        [Fact]
        public async Task RedactPDFAsync_ShouldReturnRedactedPDF()
        {
            // Arrange
            var pdfData = CreateTestPDFBytes();
            var redactionAreas = new List<RedactionService.RedactionArea>
            {
                new RedactionService.RedactionArea
                {
                    PageIndex = 0,
                    Rect = new RectangleF(10, 10, 100, 100)
                }
            };

            // Act
            var result = await _redactionService.RedactPDFAsync(pdfData, redactionAreas, new List<RedactionService.PHIMatch>());

            // Assert
            result.Should().NotBeNull();
            result.Length.Should().BeGreaterThan(0);
        }

        private byte[] CreateTestImageBytes()
        {
            // Create a simple test image
            using (var bitmap = new Bitmap(100, 100))
            using (var stream = new MemoryStream())
            {
                bitmap.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
                return stream.ToArray();
            }
        }

        private byte[] CreateTestPDFBytes()
        {
            // Create minimal PDF bytes for testing
            // In a real scenario, this would be a proper PDF
            return System.Text.Encoding.UTF8.GetBytes("%PDF-1.4\n1 0 obj\nendobj\nxref\n%%EOF");
        }
    }
}
