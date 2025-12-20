using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public class VersionViewModel : INotifyPropertyChanged
    {
        public DocumentVersion Version { get; }
        public bool IsCurrentVersion { get; }

        public VersionViewModel(DocumentVersion version, bool isCurrent)
        {
            Version = version;
            IsCurrentVersion = isCurrent;
        }

        public string VersionNumberText => IsCurrentVersion ? "Current Version" : $"Version {Version.VersionNumber}";
        public string CreatedAtText => Version.CreatedAt.ToString("MMM dd, yyyy 'at' HH:mm");
        public string? Changes => Version.Changes;
        public bool HasChanges => !string.IsNullOrWhiteSpace(Version.Changes);
        public string FileSizeText => FormatFileSize(Version.FileSize);

        private string FormatFileSize(long bytes)
        {
            if (bytes < 1024) return $"{bytes} B";
            if (bytes < 1024 * 1024) return $"{bytes / 1024} KB";
            if (bytes < 1024 * 1024 * 1024) return $"{bytes / (1024 * 1024)} MB";
            return $"{bytes / (1024 * 1024 * 1024)} GB";
        }

        public event PropertyChangedEventHandler? PropertyChanged;
    }

    public sealed partial class DocumentVersionHistoryView : Page
    {
        private Document? _document;
        private ObservableCollection<VersionViewModel> _versions = new();

        public DocumentVersionHistoryViewModel ViewModel { get; }

        public DocumentVersionHistoryView()
        {
            InitializeComponent();
            ViewModel = new DocumentVersionHistoryViewModel(_versions);
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Document document)
            {
                _document = document;
                DocumentNameTextBlock.Text = document.Name;
                DocumentTypeTextBlock.Text = $"{document.DocumentType} • {FormatFileSize(document.FileSize)}";
                await LoadVersionsAsync();
            }
        }

        private async Task LoadVersionsAsync()
        {
            // TODO: Load versions from service
            // For now, show current version only
            _versions.Clear();
            
            if (_document != null)
            {
                _versions.Add(new VersionViewModel(
                    new DocumentVersion
                    {
                        Id = _document.Id,
                        DocumentId = _document.Id,
                        VersionNumber = 1,
                        CreatedAt = _document.CreatedAt,
                        FileSize = _document.FileSize
                    },
                    isCurrent: true
                ));
            }

            UpdateEmptyState();
        }

        private void UpdateEmptyState()
        {
            if (_versions.Count <= 1) // Only current version
            {
                VersionsListView.Visibility = Visibility.Collapsed;
                EmptyStatePanel.Visibility = Visibility.Visible;
            }
            else
            {
                VersionsListView.Visibility = Visibility.Visible;
                EmptyStatePanel.Visibility = Visibility.Collapsed;
            }
        }

        private void OnVersionClick(object sender, ItemClickEventArgs e)
        {
            // Could navigate to version preview
        }

        private void OnDownloadVersionClick(object sender, RoutedEventArgs e)
        {
            if (sender is Button button && button.Tag is VersionViewModel versionVM)
            {
                // TODO: Download specific version
            }
        }

        private string FormatFileSize(long bytes)
        {
            if (bytes < 1024) return $"{bytes} B";
            if (bytes < 1024 * 1024) return $"{bytes / 1024} KB";
            if (bytes < 1024 * 1024 * 1024) return $"{bytes / (1024 * 1024)} MB";
            return $"{bytes / (1024 * 1024 * 1024)} GB";
        }
    }

    public class DocumentVersionHistoryViewModel
    {
        public ObservableCollection<VersionViewModel> Versions { get; }

        public DocumentVersionHistoryViewModel(ObservableCollection<VersionViewModel> versions)
        {
            Versions = versions;
        }
    }
}
