using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class VaultDetailView : Page, INotifyPropertyChanged
    {
        private Vault? _vault;
        private readonly VaultService _vaultService;
        private readonly DocumentService _documentService;
        private readonly VaultTransferService _transferService;
        private ObservableCollection<Document> _documents = new();
        private bool _isLoading;
        private Guid? _currentUserID;

        public event PropertyChangedEventHandler? PropertyChanged;

        public VaultDetailViewModel ViewModel { get; }

        public VaultDetailView()
        {
            InitializeComponent();
            _vaultService = App.Services.GetRequiredService<VaultService>();
            _documentService = App.Services.GetRequiredService<DocumentService>();
            _transferService = App.Services.GetRequiredService<VaultTransferService>();
            ViewModel = new VaultDetailViewModel(_vault, _documentService);
            
            // TODO: Get current user ID from authentication service
            // _currentUserID = authService.GetCurrentUserID();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                ViewModel.Vault = vault;
                
                // Show transfer button if user is owner
                // TODO: Check if current user is owner
                // TransferOwnershipButton.Visibility = (vault.OwnerID == _currentUserID) ? Visibility.Visible : Visibility.Collapsed;
                
                LoadDocumentsAsync();
            }
        }

        private async void LoadDocumentsAsync()
        {
            if (_vault == null) return;

            IsLoading = true;
            try
            {
                var documents = await _documentService.GetDocumentsForVaultAsync(_vault.Id);
                Documents = new ObservableCollection<Document>(documents);
                ViewModel.Documents = Documents;
            }
            finally
            {
                IsLoading = false;
            }
        }

        public ObservableCollection<Document> Documents
        {
            get => _documents;
            private set
            {
                _documents = value;
                OnPropertyChanged();
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
                ViewModel.IsLoading = value;
            }
        }

        private void OnUploadDocumentClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            if (_vault != null)
            {
                Frame.Navigate(typeof(DocumentUploadView), _vault);
            }
        }

        private void OnSearchDocumentsClick(object sender, RoutedEventArgs e)
        {
            Frame.Navigate(typeof(DocumentSearchView), Documents.ToList());
        }

        private void OnBulkOperationsClick(object sender, RoutedEventArgs e)
        {
            if (_vault != null)
            {
                var param = new Tuple<List<Document>, Guid>(Documents.ToList(), _vault.Id);
                Frame.Navigate(typeof(BulkOperationsView), param);
            }
        }

        private void OnURLDownloadClick(object sender, RoutedEventArgs e)
        {
            if (_vault != null)
            {
                Frame.Navigate(typeof(URLDownloadView), _vault.Id);
            }
        }

        private void OnNomineesClick(object sender, RoutedEventArgs e)
        {
            if (_vault != null)
            {
                Frame.Navigate(typeof(NomineeManagementView), _vault);
            }
        }

        private void OnTransferOwnershipClick(object sender, RoutedEventArgs e)
        {
            if (_vault != null)
            {
                Frame.Navigate(typeof(TransferOwnershipView), _vault);
            }
        }

        private async void OnCloseVaultClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            if (_vault == null) return;

            await _vaultService.CloseVaultAsync(_vault);
            Frame.GoBack();
        }

        private void OnDocumentClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is Document document)
            {
                // Could show context menu or navigate to preview
                // For now, navigate to preview
                Frame.Navigate(typeof(DocumentPreviewView), document);
            }
        }

        private void OnShowVersionHistory(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is Document document)
            {
                Frame.Navigate(typeof(DocumentVersionHistoryView), document);
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class VaultDetailViewModel
    {
        public Vault? Vault { get; set; }
        public ObservableCollection<Document> Documents { get; set; } = new();
        public bool IsLoading { get; set; }

        public VaultDetailViewModel(Vault? vault, DocumentService documentService)
        {
            Vault = vault;
        }
    }
}
