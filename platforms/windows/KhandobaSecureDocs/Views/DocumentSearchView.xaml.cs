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
    public enum DocumentSortOption
    {
        NameAscending,
        NameDescending,
        DateAscending,
        DateDescending,
        SizeAscending,
        SizeDescending
    }

    public sealed partial class DocumentSearchView : Page, INotifyPropertyChanged
    {
        private List<Document> _allDocuments = new();
        private string _searchQuery = "";
        private string? _selectedDocumentType = null;
        private DocumentSortOption _sortOption = DocumentSortOption.DateDescending;
        private ObservableCollection<Document> _filteredDocuments = new();

        public event PropertyChangedEventHandler? PropertyChanged;

        public DocumentSearchViewModel ViewModel { get; }

        public DocumentSearchView()
        {
            InitializeComponent();
            ViewModel = new DocumentSearchViewModel(_filteredDocuments, _searchQuery);
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is List<Document> documents)
            {
                _allDocuments = documents;
                ApplyFilters();
            }
        }

        private void OnSearchTextChanged(object sender, TextChangedEventArgs e)
        {
            _searchQuery = SearchTextBox.Text ?? "";
            ViewModel.HasSearchText = !string.IsNullOrWhiteSpace(_searchQuery);
            ApplyFilters();
        }

        private void OnClearSearchClick(object sender, RoutedEventArgs e)
        {
            SearchTextBox.Text = "";
            _searchQuery = "";
            ViewModel.HasSearchText = false;
            ApplyFilters();
        }

        private void OnFilterButtonClick(object sender, RoutedEventArgs e)
        {
            if (sender is ToggleButton button)
            {
                // Uncheck other buttons
                AllFilterButton.IsChecked = button == AllFilterButton;
                ImageFilterButton.IsChecked = button == ImageFilterButton;
                PdfFilterButton.IsChecked = button == PdfFilterButton;
                VideoFilterButton.IsChecked = button == VideoFilterButton;
                AudioFilterButton.IsChecked = button == AudioFilterButton;
                TextFilterButton.IsChecked = button == TextFilterButton;

                _selectedDocumentType = button.Tag?.ToString();
                if (string.IsNullOrEmpty(_selectedDocumentType))
                    _selectedDocumentType = null;

                ApplyFilters();
            }
        }

        private void OnSortChanged(object sender, SelectionChangedEventArgs e)
        {
            if (SortComboBox.SelectedItem is ComboBoxItem item && item.Tag is string tag)
            {
                _sortOption = Enum.Parse<DocumentSortOption>(tag);
                ApplyFilters();
            }
        }

        private void ApplyFilters()
        {
            var filtered = _allDocuments.AsEnumerable();

            // Filter by search query
            if (!string.IsNullOrWhiteSpace(_searchQuery))
            {
                var query = _searchQuery.ToLowerInvariant();
                filtered = filtered.Where(doc =>
                    doc.Name.ToLowerInvariant().Contains(query) ||
                    (doc.AiTags != null && doc.AiTags.Count > 0 && doc.AiTags.Any(tag => tag.ToLowerInvariant().Contains(query)))
                );
            }

            // Filter by document type
            if (_selectedDocumentType != null)
            {
                filtered = filtered.Where(doc => doc.DocumentType == _selectedDocumentType);
            }

            // Sort
            filtered = _sortOption switch
            {
                DocumentSortOption.NameAscending => filtered.OrderBy(d => d.Name),
                DocumentSortOption.NameDescending => filtered.OrderByDescending(d => d.Name),
                DocumentSortOption.DateAscending => filtered.OrderBy(d => d.CreatedAt),
                DocumentSortOption.DateDescending => filtered.OrderByDescending(d => d.CreatedAt),
                DocumentSortOption.SizeAscending => filtered.OrderBy(d => d.FileSize),
                DocumentSortOption.SizeDescending => filtered.OrderByDescending(d => d.FileSize),
                _ => filtered
            };

            _filteredDocuments.Clear();
            foreach (var doc in filtered)
            {
                _filteredDocuments.Add(doc);
            }

            ViewModel.UpdateResultsCount(_filteredDocuments.Count);
            UpdateEmptyState();
        }

        private void UpdateEmptyState()
        {
            if (_filteredDocuments.Count == 0)
            {
                EmptyStatePanel.Visibility = Visibility.Visible;
            }
            else
            {
                EmptyStatePanel.Visibility = Visibility.Collapsed;
            }
        }

        private void OnDocumentClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is Document document)
            {
                Frame.Navigate(typeof(DocumentPreviewView), document);
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class DocumentSearchViewModel : INotifyPropertyChanged
    {
        private readonly ObservableCollection<Document> _filteredDocuments;
        private int _resultsCount;
        private bool _hasSearchText;

        public DocumentSearchViewModel(ObservableCollection<Document> filteredDocuments, string searchQuery)
        {
            _filteredDocuments = filteredDocuments;
            _hasSearchText = !string.IsNullOrWhiteSpace(searchQuery);
        }

        public ObservableCollection<Document> FilteredDocuments => _filteredDocuments;

        public string ResultsCountText => $"{_resultsCount} document{(_resultsCount != 1 ? "s" : "")} found";

        public bool HasSearchText
        {
            get => _hasSearchText;
            set
            {
                _hasSearchText = value;
                OnPropertyChanged();
            }
        }

        public void UpdateResultsCount(int count)
        {
            _resultsCount = count;
            OnPropertyChanged(nameof(ResultsCountText));
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
