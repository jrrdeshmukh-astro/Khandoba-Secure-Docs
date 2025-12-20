using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Services;
using KhandobaSecureDocs.Models;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class AntiVaultManagementView : Page, INotifyPropertyChanged
    {
        private readonly AntiVaultService _antiVaultService;
        private readonly VaultService? _vaultService;
        private ObservableCollection<AntiVault> _antiVaults = new();
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public ObservableCollection<AntiVault> AntiVaults
        {
            get => _antiVaults;
            private set
            {
                _antiVaults = value;
                OnPropertyChanged();
                UpdateEmptyState();
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
                LoadingRing.IsActive = value;
            }
        }

        public AntiVaultManagementView()
        {
            InitializeComponent();
            
            // Get current user ID from authentication service
            var authService = App.Services.GetRequiredService<AuthenticationService>();
            var currentUserID = authService.CurrentUser?.Id ?? Guid.NewGuid(); // Fallback for testing
            
            var supabaseService = App.Services.GetRequiredService<SupabaseService>();
            _antiVaultService = new AntiVaultService(supabaseService, currentUserID);
            _vaultService = App.Services.GetService<VaultService>();
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            await LoadAntiVaultsAsync();
        }

        private async Task LoadAntiVaultsAsync()
        {
            IsLoading = true;
            try
            {
                await _antiVaultService.LoadAntiVaultsAsync();
                AntiVaults = _antiVaultService.AntiVaults;
            }
            finally
            {
                IsLoading = false;
            }
        }

        private void OnAntiVaultClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is AntiVault antiVault)
            {
                Frame.Navigate(typeof(AntiVaultDetailView), antiVault);
            }
        }

        private void OnCreateAntiVaultClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            Frame.Navigate(typeof(CreateAntiVaultView));
        }

        private void UpdateEmptyState()
        {
            if (AntiVaults.Count == 0 && !IsLoading)
            {
                EmptyStatePanel.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
                AntiVaultsListView.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
            }
            else
            {
                EmptyStatePanel.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
                AntiVaultsListView.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            }
        }

        private void OnPropertyChanged(string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
