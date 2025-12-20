using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using Microsoft.UI.Xaml.Navigation;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.Storage.Streams;
using WinRT.Interop;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.IO;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class DocumentPreviewView : Page
    {
        private Document? _document;
        private readonly DocumentService _documentService;
        private byte[]? _documentData;

        public DocumentPreviewView()
        {
            InitializeComponent();
            _documentService = App.Services.GetRequiredService<DocumentService>();
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Document document)
            {
                _document = document;
                await LoadDocumentPreviewAsync();
            }
            else
            {
                ShowError("Invalid document");
            }
        }

        private async Task LoadDocumentPreviewAsync()
        {
            if (_document == null) return;

            try
            {
                LoadingRing.Visibility = Visibility.Visible;
                ErrorTextBlock.Visibility = Visibility.Collapsed;
                
                // Update UI with document info
                DocumentNameTextBlock.Text = _document.Name;
                DocumentInfoTextBlock.Text = $"{_document.FileType} • {FormatFileSize(_document.FileSize)} • {_document.CreatedAt:MMM d, yyyy}";
                StatusTextBlock.Text = "Loading document...";

                // Download and decrypt document
                _documentData = await _documentService.DownloadDocumentAsync(_document);

                // Determine preview type based on file extension
                var fileName = _document.Name ?? "";
                var fileExtension = Path.GetExtension(fileName).ToLowerInvariant();
                
                // Fallback to FileType property if name doesn't have extension
                if (string.IsNullOrEmpty(fileExtension) && !string.IsNullOrEmpty(_document.FileType))
                {
                    fileExtension = _document.FileType.StartsWith(".") 
                        ? _document.FileType.ToLowerInvariant() 
                        : "." + _document.FileType.ToLowerInvariant();
                }
                
                if (IsImageFile(fileExtension))
                {
                    await ShowImagePreviewAsync(_documentData);
                }
                else if (fileExtension == ".pdf")
                {
                    ShowPdfPreview(_documentData);
                }
                else if (IsTextFile(fileExtension))
                {
                    ShowTextPreview(_documentData);
                }
                else
                {
                    ShowError($"Preview not supported for file type: {fileExtension}");
                }

                StatusTextBlock.Text = $"Document loaded • {FormatFileSize(_document.FileSize)}";
            }
            catch (Exception ex)
            {
                ShowError($"Failed to load document: {ex.Message}");
            }
            finally
            {
                LoadingRing.Visibility = Visibility.Collapsed;
            }
        }

        private async Task ShowImagePreviewAsync(byte[] imageData)
        {
            try
            {
                var bitmapImage = new BitmapImage();
                using (var stream = new InMemoryRandomAccessStream())
                {
                    await stream.WriteAsync(imageData.AsBuffer());
                    stream.Seek(0);
                    await bitmapImage.SetSourceAsync(stream);
                }

                ImagePreview.Source = bitmapImage;
                ImagePreview.Visibility = Visibility.Visible;
                TextPreview.Visibility = Visibility.Collapsed;
                PdfPreview.Visibility = Visibility.Collapsed;
                ErrorTextBlock.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                ShowError($"Failed to display image: {ex.Message}");
            }
        }

        private void ShowPdfPreview(byte[] pdfData)
        {
            try
            {
                // For PDF preview, we would need to use a PDF viewer library or WebView2 with PDF.js
                // For now, show a message that PDF preview requires additional setup
                ErrorTextBlock.Text = "PDF preview requires PDF.js or a PDF viewer library. Please download the file to view it.";
                ErrorTextBlock.Visibility = Visibility.Visible;
                LoadingRing.Visibility = Visibility.Collapsed;
                ImagePreview.Visibility = Visibility.Collapsed;
                TextPreview.Visibility = Visibility.Collapsed;
                PdfPreview.Visibility = Visibility.Collapsed;
                
                // TODO: Implement PDF preview using WebView2 with PDF.js or another PDF viewer library
            }
            catch (Exception ex)
            {
                ShowError($"Failed to display PDF: {ex.Message}");
            }
        }

        private void ShowTextPreview(byte[] textData)
        {
            try
            {
                var text = System.Text.Encoding.UTF8.GetString(textData);
                TextPreview.Text = text;
                TextPreview.Visibility = Visibility.Visible;
                ImagePreview.Visibility = Visibility.Collapsed;
                PdfPreview.Visibility = Visibility.Collapsed;
                ErrorTextBlock.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                ShowError($"Failed to display text: {ex.Message}");
            }
        }

        private void ShowError(string message)
        {
            ErrorTextBlock.Text = message;
            ErrorTextBlock.Visibility = Visibility.Visible;
            LoadingRing.Visibility = Visibility.Collapsed;
            ImagePreview.Visibility = Visibility.Collapsed;
            TextPreview.Visibility = Visibility.Collapsed;
            PdfPreview.Visibility = Visibility.Collapsed;
        }

        private bool IsImageFile(string extension)
        {
            return extension == ".jpg" || extension == ".jpeg" || extension == ".png" || 
                   extension == ".gif" || extension == ".bmp" || extension == ".webp";
        }

        private bool IsTextFile(string extension)
        {
            return extension == ".txt" || extension == ".md" || extension == ".json" || 
                   extension == ".xml" || extension == ".csv" || extension == ".log";
        }

        private async void OnDownloadClick(object sender, RoutedEventArgs e)
        {
            if (_document == null || _documentData == null) return;

            try
            {
                var savePicker = new FileSavePicker();
                savePicker.SuggestedFileName = _document.Name;
                savePicker.FileTypeChoices.Add("All Files", new[] { "*" });
                
                // Add file type choice based on extension
                var fileName = _document.Name ?? "";
                var fileExtension = Path.GetExtension(fileName);
                if (string.IsNullOrEmpty(fileExtension) && !string.IsNullOrEmpty(_document.FileType))
                {
                    fileExtension = _document.FileType.StartsWith(".") 
                        ? _document.FileType 
                        : "." + _document.FileType;
                }
                
                if (!string.IsNullOrEmpty(fileExtension))
                {
                    savePicker.FileTypeChoices.Add(
                        fileExtension.ToUpperInvariant().Substring(1) + " Files", 
                        new[] { fileExtension }
                    );
                }

                // Initialize picker for WinUI 3
                var app = Microsoft.UI.Xaml.Application.Current as App;
                var window = app?.GetActiveWindow();
                if (window != null)
                {
                    var hWnd = WinRT.Interop.WindowNative.GetWindowHandle(window);
                    WinRT.Interop.InitializeWithWindow.Initialize(savePicker, hWnd);
                }

                var file = await savePicker.PickSaveFileAsync();
                if (file != null)
                {
                    await FileIO.WriteBytesAsync(file, _documentData);
                    
                    var dialog = new ContentDialog
                    {
                        Title = "Download Complete",
                        Content = $"Document saved to: {file.Path}",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await dialog.ShowAsync();
                }
            }
            catch (Exception ex)
            {
                var dialog = new ContentDialog
                {
                    Title = "Download Failed",
                    Content = $"Failed to save document: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await dialog.ShowAsync();
            }
        }

        private async void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (_document == null) return;

            var confirmDialog = new ContentDialog
            {
                Title = "Delete Document",
                Content = $"Are you sure you want to delete '{_document.Name}'? This action cannot be undone.",
                PrimaryButtonText = "Delete",
                CloseButtonText = "Cancel",
                XamlRoot = XamlRoot,
                DefaultButton = ContentDialogButton.Close
            };

            var result = await confirmDialog.ShowAsync();
            if (result == ContentDialogResult.Primary)
            {
                try
                {
                    await _documentService.DeleteDocumentAsync(_document);
                    Frame.GoBack();
                }
                catch (Exception ex)
                {
                    var errorDialog = new ContentDialog
                    {
                        Title = "Delete Failed",
                        Content = $"Failed to delete document: {ex.Message}",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await errorDialog.ShowAsync();
                }
            }
        }

        private string FormatFileSize(long bytes)
        {
            string[] sizes = { "B", "KB", "MB", "GB" };
            double len = bytes;
            int order = 0;
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            return $"{len:0.##} {sizes[order]}";
        }
    }
}
