using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class NomineeInvitationView : Page
    {
        private Vault? _vault;
        private readonly NomineeService _nomineeService;
        private Guid? _currentUserID;

        public NomineeInvitationView()
        {
            InitializeComponent();
            _nomineeService = App.Services.GetRequiredService<NomineeService>();
            
            // TODO: Get current user ID from authentication service
            // _currentUserID = authService.GetCurrentUserID();
            
            // Enable/disable send button based on name field
            NomineeNameTextBox.TextChanged += (s, e) =>
            {
                SendButton.IsEnabled = !string.IsNullOrWhiteSpace(NomineeNameTextBox.Text) &&
                                      (!string.IsNullOrWhiteSpace(EmailTextBox.Text) ||
                                       !string.IsNullOrWhiteSpace(PhoneTextBox.Text));
            };
            
            EmailTextBox.TextChanged += (s, e) =>
            {
                SendButton.IsEnabled = !string.IsNullOrWhiteSpace(NomineeNameTextBox.Text) &&
                                      (!string.IsNullOrWhiteSpace(EmailTextBox.Text) ||
                                       !string.IsNullOrWhiteSpace(PhoneTextBox.Text));
            };
            
            PhoneTextBox.TextChanged += (s, e) =>
            {
                SendButton.IsEnabled = !string.IsNullOrWhiteSpace(NomineeNameTextBox.Text) &&
                                      (!string.IsNullOrWhiteSpace(EmailTextBox.Text) ||
                                       !string.IsNullOrWhiteSpace(PhoneTextBox.Text));
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

        private async void OnSendInvitationClick(object sender, RoutedEventArgs e)
        {
            if (_vault == null) return;

            var name = NomineeNameTextBox.Text.Trim();
            var email = EmailTextBox.Text.Trim();
            var phone = PhoneTextBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please enter nominee name",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            if (string.IsNullOrWhiteSpace(email) && string.IsNullOrWhiteSpace(phone))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please provide either email or phone number",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            SendButton.IsEnabled = false;

            try
            {
                await _nomineeService.InviteNomineeAsync(
                    vaultId: _vault.Id,
                    name: name,
                    email: string.IsNullOrWhiteSpace(email) ? null : email,
                    phoneNumber: string.IsNullOrWhiteSpace(phone) ? null : phone,
                    invitedByUserID: _currentUserID
                );

                var successDialog = new ContentDialog
                {
                    Title = "Invitation Sent",
                    Content = "The invitation has been sent successfully.",
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
                    Content = $"Failed to send invitation: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                SendButton.IsEnabled = true;
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }
    }
}
