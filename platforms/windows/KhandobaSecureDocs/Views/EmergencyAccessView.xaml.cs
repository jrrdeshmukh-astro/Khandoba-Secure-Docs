using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class EmergencyAccessView : Page
    {
        private Vault? _vault;
        private readonly EmergencyApprovalService _emergencyService;
        private string _selectedUrgency = "medium";
        private Guid? _currentUserID;

        public EmergencyAccessView()
        {
            InitializeComponent();
            _emergencyService = App.Services.GetRequiredService<EmergencyApprovalService>();
            
            // TODO: Get current user ID from authentication service
            // _currentUserID = authService.GetCurrentUserID();
            
            // Enable/disable submit button based on reason field
            ReasonTextBox.TextChanged += (s, e) =>
            {
                SubmitButton.IsEnabled = !string.IsNullOrWhiteSpace(ReasonTextBox.Text);
            };
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                VaultNameTextBlock.Text = $"Vault: {vault.Name}";
                VaultDisplayNameTextBlock.Text = vault.Name;
            }
        }

        private void OnUrgencyChecked(object sender, RoutedEventArgs e)
        {
            if (sender is RadioButton radio && radio.Tag is string urgency)
            {
                _selectedUrgency = urgency;
            }
        }

        private async void OnSubmitClick(object sender, RoutedEventArgs e)
        {
            if (_vault == null) return;

            var reason = ReasonTextBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(reason))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please provide a reason for emergency access",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            if (_currentUserID == null)
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "User not authenticated",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            SubmitButton.IsEnabled = false;

            try
            {
                await _emergencyService.CreateEmergencyRequestAsync(
                    vaultId: _vault.Id,
                    requesterID: _currentUserID.Value,
                    reason: reason,
                    urgency: _selectedUrgency
                );

                var successDialog = new ContentDialog
                {
                    Title = "Request Submitted",
                    Content = "Your emergency access request has been submitted. You will be notified when it's approved.",
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
                    Content = $"Failed to submit request: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                SubmitButton.IsEnabled = true;
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }
    }
}
