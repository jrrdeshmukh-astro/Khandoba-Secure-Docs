using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Threading.Tasks;
using Windows.Security.Credentials.UI;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class EmergencyAccessUnlockView : Page
    {
        private Vault? _vault;
        private readonly EmergencyApprovalService _emergencyService;

        public EmergencyAccessUnlockView()
        {
            InitializeComponent();
            _emergencyService = App.Services.GetRequiredService<EmergencyApprovalService>();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                VaultNameTextBlock.Text = vault.Name;
            }
        }

        private void OnPassCodeChanged(object sender, RoutedEventArgs e)
        {
            UnlockButton.IsEnabled = !string.IsNullOrWhiteSpace(PassCodePasswordBox.Password);
        }

        private async void OnUnlockClick(object sender, RoutedEventArgs e)
        {
            if (_vault == null) return;

            var passCode = PassCodePasswordBox.Password.Trim();

            if (string.IsNullOrWhiteSpace(passCode))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please enter pass code",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            UnlockButton.IsEnabled = false;

            try
            {
                // Verify pass code
                var request = await _emergencyService.VerifyEmergencyPassAsync(passCode, _vault.Id);
                if (request == null)
                {
                    var errorDialog = new ContentDialog
                    {
                        Title = "Error",
                        Content = "Invalid or expired pass code",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await errorDialog.ShowAsync();
                    return;
                }

                // Perform biometric verification
                var verificationResult = await UserConsentVerifier.RequestVerificationAsync(
                    "Verify your identity to access the vault with emergency pass code"
                );

                if (verificationResult == UserConsentVerificationResult.Verified)
                {
                    // Access granted - unlock vault
                    // TODO: Integrate with VaultService to unlock the vault

                    var successDialog = new ContentDialog
                    {
                        Title = "Access Granted",
                        Content = "Emergency access granted. The vault is now unlocked.",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await successDialog.ShowAsync();

                    Frame.GoBack();
                }
                else
                {
                    var errorDialog = new ContentDialog
                    {
                        Title = "Verification Failed",
                        Content = "Biometric verification failed. Please try again.",
                        CloseButtonText = "OK",
                        XamlRoot = XamlRoot
                    };
                    await errorDialog.ShowAsync();
                }
            }
            catch (Exception ex)
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to unlock vault: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                UnlockButton.IsEnabled = true;
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }
    }
}
