using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Services;
using KhandobaSecureDocs.Models;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class CreateAntiVaultView : Page, INotifyPropertyChanged
    {
        private readonly AntiVaultService _antiVaultService;
        private readonly VaultService _vaultService;
        private List<Vault> _availableVaults = new();
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public CreateAntiVaultView()
        {
            InitializeComponent();
            
            // Get current user ID from authentication service
            var authService = App.Services.GetRequiredService<AuthenticationService>();
            var currentUserID = authService.CurrentUser?.Id ?? Guid.NewGuid();
            
            var supabaseService = App.Services.GetRequiredService<SupabaseService>();
            _antiVaultService = new AntiVaultService(supabaseService, currentUserID);
            _vaultService = App.Services.GetRequiredService<VaultService>();
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            await LoadVaultsAsync();
        }

        private async Task LoadVaultsAsync()
        {
            _isLoading = true;
            try
            {
                await _vaultService.LoadVaultsAsync();
                _availableVaults = _vaultService.Vaults
                    .Where(v => !v.IsAntiVault && !v.IsSystemVault)
                    .ToList();
                
                VaultComboBox.ItemsSource = _availableVaults;
            }
            finally
            {
                _isLoading = false;
            }
        }

        private void OnVaultSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            CreateButton.IsEnabled = VaultComboBox.SelectedItem != null;
        }

        private async void OnCreateClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            if (VaultComboBox.SelectedItem is not Vault selectedVault)
            {
                ErrorMessageText.Text = "Please select a vault to monitor";
                ErrorMessageText.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
                return;
            }

            ErrorMessageText.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
            CreateButton.IsEnabled = false;

            try
            {
                var authService = App.Services.GetRequiredService<AuthenticationService>();
                var ownerID = authService.CurrentUser?.Id ?? Guid.NewGuid();

                var threatSettings = new ThreatDetectionSettings
                {
                    DetectContentDiscrepancies = DetectContentCheck.IsChecked == true,
                    DetectMetadataMismatches = DetectMetadataCheck.IsChecked == true,
                    DetectAccessPatternAnomalies = DetectAccessPatternCheck.IsChecked == true,
                    DetectGeographicInconsistencies = DetectGeographicCheck.IsChecked == true,
                    DetectEditHistoryDiscrepancies = DetectEditHistoryCheck.IsChecked == true,
                    MinThreatSeverity = ((ComboBoxItem)SeverityComboBox.SelectedItem)?.Content?.ToString()?.ToLower() ?? "medium"
                };

                var antiVault = await _antiVaultService.CreateAntiVaultAsync(
                    monitoredVault: selectedVault,
                    ownerID: ownerID,
                    settings: threatSettings
                );

                // Update auto-unlock policy
                antiVault.AutoUnlockPolicy = new AutoUnlockPolicy
                {
                    UnlockOnSessionNomination = UnlockOnSessionCheck.IsChecked == true,
                    UnlockOnSubsetNomination = UnlockOnSubsetCheck.IsChecked == true,
                    RequireApproval = RequireApprovalCheck.IsChecked == true
                };

                // Navigate back or to detail view
                Frame.GoBack();
            }
            catch (Exception ex)
            {
                ErrorMessageText.Text = ex.Message;
                ErrorMessageText.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
                CreateButton.IsEnabled = true;
            }
        }

        private void OnCancelClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            Frame.GoBack();
        }

        private void OnPropertyChanged(string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
