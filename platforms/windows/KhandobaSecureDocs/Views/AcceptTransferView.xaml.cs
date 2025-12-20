using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Services;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class AcceptTransferView : Page
    {
        private readonly VaultTransferService _transferService;

        public AcceptTransferView()
        {
            InitializeComponent();
            _transferService = App.Services.GetRequiredService<VaultTransferService>();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is string token)
            {
                TransferTokenTextBox.Text = token;
                AcceptButton.IsEnabled = !string.IsNullOrWhiteSpace(token);
            }
        }

        private void OnTokenTextChanged(object sender, Microsoft.UI.Xaml.Controls.TextChangedEventArgs e)
        {
            AcceptButton.IsEnabled = !string.IsNullOrWhiteSpace(TransferTokenTextBox.Text);
        }

        private async void OnAcceptClick(object sender, RoutedEventArgs e)
        {
            var token = TransferTokenTextBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(token))
            {
                var errorDialog = new ContentDialog
                {
                    Title = "Error",
                    Content = "Please enter transfer token",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
                return;
            }

            LoadingRing.IsActive = true;
            AcceptButton.IsEnabled = false;

            try
            {
                await _transferService.AcceptOwnershipTransferAsync(token);

                var successDialog = new ContentDialog
                {
                    Title = "Transfer Accepted",
                    Content = "You are now the owner of this vault.",
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
                    Content = $"Failed to accept transfer: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await errorDialog.ShowAsync();
            }
            finally
            {
                LoadingRing.IsActive = false;
                AcceptButton.IsEnabled = true;
            }
        }
    }
}
