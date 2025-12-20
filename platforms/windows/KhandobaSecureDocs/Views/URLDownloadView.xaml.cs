using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Services;
using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class URLDownloadView : Page
    {
        private Guid? _vaultId;
        private readonly DocumentService _documentService;
        private readonly HttpClient _httpClient;

        public URLDownloadView()
        {
            InitializeComponent();
            _documentService = App.Services.GetRequiredService<DocumentService>();
            _httpClient = new HttpClient();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Guid vaultId)
            {
                _vaultId = vaultId;
            }
        }

        private void OnUrlTextChanged(object sender, Microsoft.UI.Xaml.Controls.TextChangedEventArgs e)
        {
            var url = UrlTextBox.Text?.Trim() ?? "";
            var isValid = IsValidUrl(url);
            
            DownloadButton.IsEnabled = isValid && !string.IsNullOrWhiteSpace(url);
            
            if (!string.IsNullOrWhiteSpace(url) && !isValid)
            {
                UrlErrorTextBlock.Visibility = Visibility.Visible;
            }
            else
            {
                UrlErrorTextBlock.Visibility = Visibility.Collapsed;
            }
        }

        private bool IsValidUrl(string url)
        {
            return Uri.TryCreate(url, UriKind.Absolute, out var result) &&
                   (result.Scheme == Uri.UriSchemeHttp || result.Scheme == Uri.UriSchemeHttps);
        }

        private async void OnDownloadClick(object sender, RoutedEventArgs e)
        {
            if (_vaultId == null) return;

            var url = UrlTextBox.Text?.Trim();
            if (string.IsNullOrWhiteSpace(url) || !IsValidUrl(url))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please enter a valid URL",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            DownloadButton.IsEnabled = false;

            try
            {
                // Download file from URL
                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();

                var fileBytes = await response.Content.ReadAsByteArrayAsync();
                
                // Determine file name
                var fileName = FileNameTextBox.Text?.Trim();
                if (string.IsNullOrWhiteSpace(fileName))
                {
                    // Extract from URL or Content-Disposition header
                    fileName = ExtractFileNameFromUrl(url) ?? 
                              ExtractFileNameFromContentDisposition(response) ?? 
                              "downloaded_file";
                }

                // Save to temporary file and upload
                var tempFile = await Windows.Storage.ApplicationData.Current.TemporaryFolder
                    .CreateFileAsync(fileName, Windows.Storage.CreationCollisionOption.ReplaceExisting);
                
                await Windows.Storage.FileIO.WriteBytesAsync(tempFile, fileBytes);

                // Upload using DocumentService
                // Note: DocumentService.UploadDocumentAsync expects StorageFile, which we now have
                await _documentService.UploadDocumentAsync(_vaultId.Value, tempFile);

                var successDialog = new ContentDialog
                {
                    Title = "Download Successful",
                    Content = $"File downloaded and uploaded to vault successfully.",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await successDialog.ShowAsync();

                Frame.GoBack();
            }
            catch (Exception ex)
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to download file: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                DownloadButton.IsEnabled = true;
            }
        }

        private string? ExtractFileNameFromUrl(string url)
        {
            try
            {
                var uri = new Uri(url);
                var path = uri.AbsolutePath;
                if (!string.IsNullOrEmpty(path))
                {
                    var fileName = Path.GetFileName(path);
                    if (!string.IsNullOrEmpty(fileName))
                    {
                        return fileName;
                    }
                }
            }
            catch
            {
                // Ignore errors
            }
            return null;
        }

        private string? ExtractFileNameFromContentDisposition(HttpResponseMessage response)
        {
            if (response.Content.Headers.ContentDisposition != null)
            {
                var contentDisposition = response.Content.Headers.ContentDisposition;
                if (!string.IsNullOrEmpty(contentDisposition.FileName))
                {
                    var fileName = contentDisposition.FileName.Trim('"');
                    return fileName;
                }
            }
            return null;
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }
    }
}
