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
    public sealed partial class AntiVaultDetailView : Page, INotifyPropertyChanged
    {
        private AntiVault? _antiVault;
        private readonly AntiVaultService _antiVaultService;
        private ObservableCollection<ThreatDetection> _detectedThreats = new();

        public event PropertyChangedEventHandler? PropertyChanged;

        public AntiVaultDetailView()
        {
            InitializeComponent();
            
            // Get current user ID from authentication service
            var authService = App.Services.GetRequiredService<AuthenticationService>();
            var currentUserID = authService.CurrentUser?.Id ?? Guid.NewGuid();
            
            var supabaseService = App.Services.GetRequiredService<SupabaseService>();
            _antiVaultService = new AntiVaultService(supabaseService, currentUserID);
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is AntiVault antiVault)
            {
                _antiVault = antiVault;
                LoadAntiVaultData();
                await LoadThreatsAsync();
            }
        }

        private void LoadAntiVaultData()
        {
            if (_antiVault == null) return;

            StatusText.Text = _antiVault.Status;
            MonitoredVaultText.Text = $"Vault ID: {_antiVault.MonitoredVaultID}";

            if (_antiVault.LastUnlockedAt.HasValue)
            {
                LastUnlockedText.Text = $"Last unlocked: {_antiVault.LastUnlockedAt.Value:MMM d, yyyy 'at' h:mm tt}";
                LastUnlockedText.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            }

            // Auto-Unlock Policy
            UnlockOnSessionCheck.IsChecked = _antiVault.AutoUnlockPolicy.UnlockOnSessionNomination;
            UnlockOnSubsetCheck.IsChecked = _antiVault.AutoUnlockPolicy.UnlockOnSubsetNomination;
            RequireApprovalCheck.IsChecked = _antiVault.AutoUnlockPolicy.RequireApproval;

            // Threat Detection Settings
            DetectContentCheck.IsChecked = _antiVault.ThreatDetectionSettings.DetectContentDiscrepancies;
            DetectMetadataCheck.IsChecked = _antiVault.ThreatDetectionSettings.DetectMetadataMismatches;
            DetectAccessPatternCheck.IsChecked = _antiVault.ThreatDetectionSettings.DetectAccessPatternAnomalies;
            DetectGeographicCheck.IsChecked = _antiVault.ThreatDetectionSettings.DetectGeographicInconsistencies;
            DetectEditHistoryCheck.IsChecked = _antiVault.ThreatDetectionSettings.DetectEditHistoryDiscrepancies;
            MinThreatSeverityText.Text = $"Minimum Threat Severity: {_antiVault.ThreatDetectionSettings.MinThreatSeverity.ToUpper()}";

            // Show unlock button if locked
            if (_antiVault.Status == "locked")
            {
                UnlockButton.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            }
        }

        private async Task LoadThreatsAsync()
        {
            if (_antiVault == null) return;

            await _antiVaultService.LoadThreatsForAntiVaultAsync(_antiVault.Id);
            _detectedThreats = _antiVaultService.DetectedThreats;

            if (_detectedThreats.Count > 0)
            {
                ThreatsCard.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
                ThreatsListView.ItemsSource = _detectedThreats.Take(3);
            }
        }

        private async void OnUnlockClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            if (_antiVault == null) return;

            await _antiVaultService.UnlockAntiVaultAsync(_antiVault, _antiVault.MonitoredVaultID);
            
            // Refresh data
            LoadAntiVaultData();
        }

        private void OnViewAllThreatsClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            // Navigate to full threats view
            // TODO: Implement ThreatDetectionView
        }

        private void OnPropertyChanged(string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
