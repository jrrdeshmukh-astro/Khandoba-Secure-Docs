using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class TransferOwnershipView : Page
    {
        private Vault? _vault;
        private readonly VaultTransferService _transferService;

        public TransferOwnershipView()
        {
            InitializeComponent();
            _transferService = App.Services.GetRequiredService<VaultTransferService>();
            
            // Enable/disable button based on name field
            NewOwnerNameTextBox.TextChanged += (s, e) =>
            {
                TransferButton.IsEnabled = !string.IsNullOrWhiteSpace(NewOwnerNameTextBox.Text);
            };
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                VaultNameTextBlock.Text = vault.Name;
            }
        }

        private async void OnTransferClick(object sender, RoutedEventArgs e)
        {
            if (_vault == null) return;

            var name = NewOwnerNameTextBox.Text.Trim();
            var email = NewOwnerEmailTextBox.Text.Trim();
            var phone = NewOwnerPhoneTextBox.Text.Trim();
            var reason = ReasonTextBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please enter new owner name",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            TransferButton.IsEnabled = false;

            try
            {
                var transferRequest = await _transferService.RequestOwnershipTransferAsync(
                    vault: _vault,
                    newOwnerEmail: string.IsNullOrWhiteSpace(email) ? null : email,
                    newOwnerPhone: string.IsNullOrWhiteSpace(phone) ? null : phone,
                    newOwnerName: name,
                    reason: string.IsNullOrWhiteSpace(reason) ? null : reason
                );

                // Show transfer token dialog
                var tokenDialog = new ContentDialog
                {
                    Title = "Transfer Request Created",
                    Content = $"Transfer request created. Share this token with the new owner:\n\n{transferRequest.TransferToken}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await tokenDialog.ShowAsync();

                Frame.GoBack();
            }
            catch (Exception ex)
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to create transfer request: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                TransferButton.IsEnabled = true;
            }
        }
    }
}
