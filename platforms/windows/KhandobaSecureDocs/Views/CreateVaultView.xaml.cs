using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Services;
using System.ComponentModel;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class CreateVaultView : Page, INotifyPropertyChanged
    {
        private readonly VaultService _vaultService;
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        public CreateVaultView()
        {
            InitializeComponent();
            _vaultService = App.Services.GetRequiredService<VaultService>();
        }

        private async void OnCreateClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            var name = NameTextBox.Text?.Trim();
            if (string.IsNullOrEmpty(name))
            {
                // Show error
                return;
            }

            var description = DescriptionTextBox.Text?.Trim();
            var keyType = (KeyTypeComboBox.SelectedItem as ComboBoxItem)?.Tag?.ToString() ?? "single";

            IsLoading = true;
            try
            {
                await _vaultService.CreateVaultAsync(name, description, keyType);
                Frame.GoBack();
            }
            catch (System.Exception ex)
            {
                // Show error message
                Console.WriteLine($"❌ Failed to create vault: {ex.Message}");
            }
            finally
            {
                IsLoading = false;
            }
        }

        private void OnCancelClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            Frame.GoBack();
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
