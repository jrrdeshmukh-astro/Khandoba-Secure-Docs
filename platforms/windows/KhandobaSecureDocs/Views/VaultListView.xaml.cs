using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.ViewModels;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class VaultListView : Page, INotifyPropertyChanged
    {
        public VaultViewModel ViewModel { get; }
        private readonly BroadcastVaultService _broadcastVaultService;
        private List<Vault> _broadcastVaults = new();

        public event PropertyChangedEventHandler? PropertyChanged;

        public List<Vault> BroadcastVaults => _broadcastVaults;
        public bool HasBroadcastVaults => _broadcastVaults.Count > 0;

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public VaultListView()
        {
            InitializeComponent();
            ViewModel = App.Services.GetRequiredService<VaultViewModel>();
            _broadcastVaultService = App.Services.GetRequiredService<BroadcastVaultService>();
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            // Ensure Open Street vault exists and load broadcast vaults
            try
            {
                await _broadcastVaultService.GetOrCreateOpenStreetVaultAsync();
                await LoadBroadcastVaultsAsync();
            }
            catch
            {
                // Handle error silently
            }
        }

        private async Task LoadBroadcastVaultsAsync()
        {
            try
            {
                // Ensure Open Street vault exists
                await _broadcastVaultService.GetOrCreateOpenStreetVaultAsync();
                
                // Get all vaults from ViewModel (which uses VaultService)
                await ViewModel.LoadVaultsAsync();
                
                // Get all vaults including system vaults
                var vaultService = App.Services.GetRequiredService<VaultService>();
                await vaultService.LoadVaultsAsync();
                var allVaults = vaultService.Vaults;
                
                // Filter broadcast vaults
                _broadcastVaults = _broadcastVaultService.GetBroadcastVaults(allVaults);
                
                // Update UI visibility
                if (_broadcastVaults.Count > 0)
                {
                    BroadcastVaultsPanel.Visibility = Visibility.Visible;
                }
                else
                {
                    BroadcastVaultsPanel.Visibility = Visibility.Collapsed;
                }
                
                // Notify property changes
                OnPropertyChanged(nameof(BroadcastVaults));
                OnPropertyChanged(nameof(HasBroadcastVaults));
            }
            catch
            {
                // Handle error silently - broadcast vaults are optional
            }
        }

        private void OnCreateVaultClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            Frame.Navigate(typeof(CreateVaultView));
        }

        private void OnVaultClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is Vault vault)
            {
                Frame.Navigate(typeof(VaultDetailView), vault);
            }
        }
    }
}
