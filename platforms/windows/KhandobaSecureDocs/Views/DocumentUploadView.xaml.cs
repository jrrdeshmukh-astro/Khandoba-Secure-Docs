using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.System;
using WinRT.Interop;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class DocumentUploadView : Page
    {
        private Vault? _vault;
        private readonly DocumentService _documentService;
        private StorageFile? _selectedFile;
        
        public DocumentUploadViewModel ViewModel { get; }

        public DocumentUploadView()
        {
            InitializeComponent();
            _documentService = App.Services.GetRequiredService<DocumentService>();
            ViewModel = new DocumentUploadViewModel();
            SelectedFileBorder.Visibility = Visibility.Collapsed;
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                ViewModel.Vault = vault;
                VaultNameTextBlock.Text = $"Vault: {vault.Name}";
                
                // Filter upload options based on vault type
                UpdateUploadOptionsVisibility();
            }
        }

        private void UpdateUploadOptionsVisibility()
        {
            if (_vault == null) return;

            // Show source options (Camera, Photos) only for source/both vaults
            if (_vault.VaultType == "source" || _vault.VaultType == "both")
            {
                SourceOptionsPanel.Visibility = Visibility.Visible;
            }
            else
            {
                SourceOptionsPanel.Visibility = Visibility.Collapsed;
            }

            // Show sink options (Files) only for sink/both vaults
            if (_vault.VaultType == "sink" || _vault.VaultType == "both")
            {
                SinkOptionsPanel.Visibility = Visibility.Visible;
            }
            else
            {
                SinkOptionsPanel.Visibility = Visibility.Collapsed;
            }
        }

        private async void OnCameraClick(object sender, RoutedEventArgs e)
        {
            // TODO: Implement camera capture for Windows
            // This requires CameraCaptureUI or MediaCapture API
            // For now, show a message
            var dialog = new ContentDialog
            {
                Title = "Camera Not Available",
                Content = "Camera capture is not yet implemented on Windows. Please use the file picker instead.",
                CloseButtonText = "OK",
                XamlRoot = XamlRoot
            };
            await dialog.ShowAsync();
        }

        private async void OnFilePickerClick(object sender, RoutedEventArgs e)
        {
            try
            {
                var filePicker = new FileOpenPicker();
                filePicker.ViewMode = PickerViewMode.Thumbnail;
                filePicker.SuggestedStartLocation = PickerLocationId.PicturesLibrary;
                
                // Add file type filters
                filePicker.FileTypeFilter.Add(".jpg");
                filePicker.FileTypeFilter.Add(".jpeg");
                filePicker.FileTypeFilter.Add(".png");
                filePicker.FileTypeFilter.Add(".pdf");
                filePicker.FileTypeFilter.Add(".doc");
                filePicker.FileTypeFilter.Add(".docx");
                filePicker.FileTypeFilter.Add(".txt");
                filePicker.FileTypeFilter.Add("*"); // All files
                
                // Initialize picker for WinUI 3
                // Get window handle from this page's window
                var window = (Microsoft.UI.Xaml.Window)((Microsoft.UI.Xaml.FrameworkElement)this).XamlRoot?.Content;
                if (window != null)
                {
                    var windowHandle = WindowNative.GetWindowHandle(window);
                    InitializeWithWindow.Initialize(filePicker, windowHandle);
                }
                
                _selectedFile = await filePicker.PickSingleFileAsync();
                
                if (_selectedFile != null)
                {
                    ViewModel.SelectedFile = _selectedFile;
                    SelectedFileNameTextBlock.Text = _selectedFile.Name;
                    SelectedFileBorder.Visibility = Visibility.Visible;
                    
                    var properties = await _selectedFile.GetBasicPropertiesAsync();
                    SelectedFileSizeTextBlock.Text = FormatFileSize(properties.Size);
                }
                else
                {
                    SelectedFileBorder.Visibility = Visibility.Collapsed;
                }
            }
            catch (Exception ex)
            {
                var dialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to pick file: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await dialog.ShowAsync();
            }
        }

        private async void OnUploadClick(object sender, RoutedEventArgs e)
        {
            if (_vault == null || _selectedFile == null)
            {
                return;
            }

            try
            {
                ViewModel.IsUploading = true;
                ViewModel.UploadProgress = 0;
                ViewModel.UploadStatus = "Preparing upload...";
                
                await _documentService.UploadDocumentAsync(_vault.Id, _selectedFile);
                
                ViewModel.UploadProgress = 100;
                ViewModel.UploadStatus = "Upload complete!";
                
                // Navigate back after a short delay
                await Task.Delay(1000);
                Frame.GoBack();
            }
            catch (Exception ex)
            {
                ViewModel.IsUploading = false;
                var dialog = new ContentDialog
                {
                    Title = "Upload Failed",
                    Content = $"Failed to upload document: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await dialog.ShowAsync();
            }
            finally
            {
                ViewModel.IsUploading = false;
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }

        private string FormatFileSize(ulong bytes)
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

    public class DocumentUploadViewModel : INotifyPropertyChanged
    {
        private Vault? _vault;
        private StorageFile? _selectedFile;
        private bool _isUploading;
        private double _uploadProgress;
        private string _uploadStatus = "";

        public Vault? Vault
        {
            get => _vault;
            set
            {
                _vault = value;
                OnPropertyChanged();
            }
        }

        public StorageFile? SelectedFile
        {
            get => _selectedFile;
            set
            {
                _selectedFile = value;
                OnPropertyChanged();
            }
        }

        public bool IsUploading
        {
            get => _isUploading;
            set
            {
                _isUploading = value;
                OnPropertyChanged();
            }
        }

        public double UploadProgress
        {
            get => _uploadProgress;
            set
            {
                _uploadProgress = value;
                OnPropertyChanged();
            }
        }

        public string UploadStatus
        {
            get => _uploadStatus;
            set
            {
                _uploadStatus = value;
                OnPropertyChanged();
            }
        }

        public bool CanUpload => SelectedFile != null && !IsUploading;

        public event PropertyChangedEventHandler? PropertyChanged;

        private void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
