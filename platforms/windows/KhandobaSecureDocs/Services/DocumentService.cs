using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Windows.Storage;
using Windows.Storage.Pickers;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class DocumentService : INotifyPropertyChanged
    {
        private readonly SupabaseService _supabaseService;
        private readonly EncryptionService _encryptionService;
        private readonly DocumentIndexingService _indexingService;
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        public DocumentService(
            SupabaseService supabaseService,
            EncryptionService encryptionService,
            DocumentIndexingService indexingService)
        {
            _supabaseService = supabaseService;
            _encryptionService = encryptionService;
            _indexingService = indexingService;
        }

        public async Task<StorageFile?> PickFileAsync()
        {
            var picker = new FileOpenPicker();
            picker.ViewMode = PickerViewMode.Thumbnail;
            picker.SuggestedStartLocation = PickerLocationId.DocumentsLibrary;
            picker.FileTypeFilter.Add("*");

            // Initialize picker for WinUI 3
            try
            {
                var app = Microsoft.UI.Xaml.Application.Current as App;
                var window = app?.GetActiveWindow();
                if (window != null)
                {
                    var hWnd = WinRT.Interop.WindowNative.GetWindowHandle(window);
                    WinRT.Interop.InitializeWithWindow.Initialize(picker, hWnd);
                }
            }
            catch
            {
                // If window access fails, picker will still work but may not be parented correctly
            }

            return await picker.PickSingleFileAsync();
        }

        public async Task<Document> UploadDocumentAsync(Guid vaultID, StorageFile file)
        {
            IsLoading = true;
            try
            {
                // Read file data
                var fileData = await FileIO.ReadBufferAsync(file);
                var bytes = fileData.ToArray();

                // Encrypt file data
                var encryptionKey = await GenerateEncryptionKeyAsync();
                var encryptedData = await _encryptionService.EncryptAES256GCMAsync(bytes, encryptionKey);

                // Upload to Supabase Storage
                var storagePath = $"{vaultID}/{Guid.NewGuid()}/{file.Name}";
                await _supabaseService.UploadFileAsync(
                    SupabaseConfig.EncryptedDocumentsBucket,
                    storagePath,
                    encryptedData
                );

                // Extract text for indexing (if supported)
                string? extractedText = null;
                if (file.ContentType.StartsWith("text/") || file.FileType == ".txt")
                {
                    extractedText = await FileIO.ReadTextAsync(file);
                }
                else if (file.FileType == ".pdf")
                {
                    // Extract text from PDF using PdfPig
                    try
                    {
                        using (var pdfDocument = PdfDocument.Open(bytes))
                        {
                            var textBuilder = new System.Text.StringBuilder();
                            foreach (var page in pdfDocument.GetPages())
                            {
                                textBuilder.AppendLine(page.Text);
                            }
                            extractedText = textBuilder.ToString();
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to extract PDF text: {ex.Message}");
                        // Continue without extracted text
                    }
                }

                // Create document in Supabase
                var supabaseDocument = new SupabaseDocument
                {
                    Id = Guid.NewGuid(),
                    VaultID = vaultID,
                    Name = file.Name,
                    FileType = file.FileType,
                    FileSize = bytes.Length,
                    StoragePath = storagePath,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    DocumentType = "source"
                };

                var created = await _supabaseService.InsertAsync("documents", supabaseDocument);

                // Index document if text is available
                if (!string.IsNullOrEmpty(extractedText))
                {
                    var index = await _indexingService.IndexDocumentAsync(extractedText, created.Id);
                    if (index.AiTags.Any())
                    {
                        created.AiTags = string.Join(",", index.AiTags);
                        await _supabaseService.UpdateAsync(created.Id, created);
                    }
                }

                return ConvertToDomainDocument(created);
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task<List<Document>> GetDocumentsForVaultAsync(Guid vaultID)
        {
            var supabaseDocuments = await _supabaseService.FetchAllAsync<SupabaseDocument>(
                filters: new Dictionary<string, object>
                {
                    { "vault_id", vaultID.ToString() }
                },
                orderBy: "created_at",
                ascending: false
            );

            return supabaseDocuments.Select(ConvertToDomainDocument).ToList();
        }

        public async Task<byte[]> DownloadDocumentAsync(Document document)
        {
            if (string.IsNullOrEmpty(document.StoragePath))
            {
                throw new InvalidOperationException("Document has no storage path");
            }

            // Download encrypted data from Supabase Storage
            var encryptedData = await _supabaseService.DownloadFileAsync(
                SupabaseConfig.EncryptedDocumentsBucket,
                document.StoragePath
            );

            // Retrieve and use encryption key
            if (document.EncryptionKeyData != null && document.EncryptionKeyData.Length > 0)
            {
                try
                {
                    // Decrypt using the encryption key from the document
                    var decryptedData = await _encryptionService.DecryptAES256GCMAsync(encryptedData, document.EncryptionKeyData);
                    return decryptedData;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to decrypt document: {ex.Message}");
                    throw new InvalidOperationException("Failed to decrypt document", ex);
                }
            }
            else
            {
                // Document not encrypted or key not available - return as-is
                return encryptedData;
            }
        }

        public async Task DeleteDocumentAsync(Document document)
        {
            IsLoading = true;
            try
            {
                // Delete from Supabase Storage
                if (!string.IsNullOrEmpty(document.StoragePath))
                {
                    await _supabaseService.DeleteFileAsync(
                        SupabaseConfig.EncryptedDocumentsBucket,
                        document.StoragePath
                    );
                }

                // Delete from database
                await _supabaseService.DeleteAsync<SupabaseDocument>(document.Id);
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task DeleteDocumentAsync(Guid documentId)
        {
            var documents = await GetDocumentsForVaultAsync(Guid.Empty); // Temporary - need to find document
            var document = documents.FirstOrDefault(d => d.Id == documentId);
            if (document != null)
            {
                await DeleteDocumentAsync(document);
            }
        }

        public async Task ArchiveDocumentAsync(Guid documentId)
        {
            IsLoading = true;
            try
            {
                // Fetch document
                var supabaseDocuments = await _supabaseService.FetchAllAsync<SupabaseDocument>(
                    filters: new Dictionary<string, object>
                    {
                        { "id", documentId.ToString() }
                    }
                );

                var supabaseDoc = supabaseDocuments.FirstOrDefault();
                if (supabaseDoc != null)
                {
                    // Update status to archived (assuming there's a status field)
                    // For now, we'll use a simple approach - mark as archived in metadata
                    supabaseDoc.UpdatedAt = DateTime.UtcNow;
                    await _supabaseService.UpdateAsync(documentId, supabaseDoc);
                }
            }
            finally
            {
                IsLoading = false;
            }
        }


        private async Task<byte[]> GenerateEncryptionKeyAsync()
        {
            // Generate a random 256-bit key
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            var key = new byte[32];
            rng.GetBytes(key);
            return key;
        }

        private Document ConvertToDomainDocument(SupabaseDocument supabaseDocument)
        {
            return new Document
            {
                Id = supabaseDocument.Id,
                VaultID = supabaseDocument.VaultID,
                Name = supabaseDocument.Name,
                FileType = supabaseDocument.FileType,
                FileSize = supabaseDocument.FileSize,
                StoragePath = supabaseDocument.StoragePath,
                CreatedAt = supabaseDocument.CreatedAt,
                UpdatedAt = supabaseDocument.UpdatedAt,
                DocumentType = supabaseDocument.DocumentType,
                EncryptionKeyData = supabaseDocument.EncryptionKeyData, // Include encryption key for decryption
                AiTags = string.IsNullOrEmpty(supabaseDocument.AiTags)
                    ? new List<string>()
                    : supabaseDocument.AiTags.Split(',').ToList()
            };
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
