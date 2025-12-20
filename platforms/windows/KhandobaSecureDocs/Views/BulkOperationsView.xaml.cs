using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public class SelectableDocument : INotifyPropertyChanged
    {
        public Document Document { get; }
        private bool _isSelected;

        public SelectableDocument(Document document)
        {
            Document = document;
        }

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                _isSelected = value;
                OnPropertyChanged();
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public sealed partial class BulkOperationsView : Page
    {
        private readonly DocumentService _documentService;
        private ObservableCollection<SelectableDocument> _selectableDocuments = new();
        private Guid? _vaultId;

        public BulkOperationsView()
        {
            InitializeComponent();
            _documentService = App.Services.GetRequiredService<DocumentService>();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Tuple<List<Document>, Guid> param)
            {
                var documents = param.Item1;
                _vaultId = param.Item2;
                
                _selectableDocuments.Clear();
                foreach (var doc in documents)
                {
                    _selectableDocuments.Add(new SelectableDocument(doc));
                }
                
                DocumentsListView.ItemsSource = _selectableDocuments;
                
                // Subscribe to selection changes
                foreach (var item in _selectableDocuments)
                {
                    item.PropertyChanged += OnDocumentSelectionChanged;
                }
            }
        }

        private void OnDocumentSelectionChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(SelectableDocument.IsSelected))
            {
                UpdateSelectionUI();
            }
        }

        private void UpdateSelectionUI()
        {
            var selectedCount = _selectableDocuments.Count(d => d.IsSelected);
            SelectionCountTextBlock.Text = $"{selectedCount} selected";
            
            if (selectedCount > 0)
            {
                ActionButtonsPanel.Visibility = Visibility.Visible;
                ClearSelectionButton.Visibility = Visibility.Visible;
            }
            else
            {
                ActionButtonsPanel.Visibility = Visibility.Collapsed;
                ClearSelectionButton.Visibility = Visibility.Collapsed;
            }
        }

        private void OnSelectAllClick(object sender, RoutedEventArgs e)
        {
            var allSelected = _selectableDocuments.All(d => d.IsSelected);
            foreach (var doc in _selectableDocuments)
            {
                doc.IsSelected = !allSelected;
            }
            
            SelectAllButton.Content = allSelected ? "Select All" : "Deselect All";
        }

        private void OnClearSelectionClick(object sender, RoutedEventArgs e)
        {
            foreach (var doc in _selectableDocuments)
            {
                doc.IsSelected = false;
            }
            SelectAllButton.Content = "Select All";
        }

        private async void OnBulkArchiveClick(object sender, RoutedEventArgs e)
        {
            var selectedDocs = _selectableDocuments.Where(d => d.IsSelected).Select(d => d.Document).ToList();
            if (selectedDocs.Count == 0) return;

            var confirmDialog = new ContentDialog
            {
                Title = "Archive Documents",
                Content = $"Are you sure you want to archive {selectedDocs.Count} document(s)?",
                PrimaryButtonText = "Archive",
                CloseButtonText = "Cancel",
                XamlRoot = XamlRoot,
                DefaultButton = ContentDialogButton.Close
            };

            var result = await confirmDialog.ShowAsync();
            if (result == ContentDialogResult.Primary)
            {
                try
                {
                    foreach (var doc in selectedDocs)
                    {
                        await _documentService.ArchiveDocumentAsync(doc.Id);
                    }

                    var successDialog = new ContentDialog
                    {
                        Title = "Success",
                        Content = $"{selectedDocs.Count} document(s) archived successfully.",
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
                        Content = $"Failed to archive documents: {ex.Message}",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await errorDialog.ShowAsync();
                }
            }
        }

        private async void OnBulkDeleteClick(object sender, RoutedEventArgs e)
        {
            var selectedDocs = _selectableDocuments.Where(d => d.IsSelected).Select(d => d.Document).ToList();
            if (selectedDocs.Count == 0) return;

            var confirmDialog = new ContentDialog
            {
                Title = "Delete Documents",
                Content = $"Are you sure you want to delete {selectedDocs.Count} document(s)? This action cannot be undone.",
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
                    foreach (var doc in selectedDocs)
                    {
                        await _documentService.DeleteDocumentAsync(doc);
                    }

                    var successDialog = new ContentDialog
                    {
                        Title = "Success",
                        Content = $"{selectedDocs.Count} document(s) deleted successfully.",
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
                        Content = $"Failed to delete documents: {ex.Message}",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await errorDialog.ShowAsync();
                }
            }
        }
    }
}
