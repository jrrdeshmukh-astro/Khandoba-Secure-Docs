using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;
using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class NomineeManagementView : Page, INotifyPropertyChanged
    {
        private Vault? _vault;
        private readonly NomineeService _nomineeService;
        private ObservableCollection<NomineeViewModel> _nominees = new();
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public NomineeManagementViewModel ViewModel { get; }

        public NomineeManagementView()
        {
            InitializeComponent();
            _nomineeService = App.Services.GetRequiredService<NomineeService>();
            ViewModel = new NomineeManagementViewModel(_nominees);
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            if (e.Parameter is Vault vault)
            {
                _vault = vault;
                ViewModel.Vault = vault;
                VaultNameTextBlock.Text = $"Vault: {vault.Name}";
                await LoadNomineesAsync();
            }
        }

        private async Task LoadNomineesAsync()
        {
            if (_vault == null) return;

            IsLoading = true;
            try
            {
                var nominees = await _nomineeService.GetNomineesForVaultAsync(_vault.Id);
                _nominees.Clear();
                foreach (var nominee in nominees)
                {
                    _nominees.Add(new NomineeViewModel(nominee));
                }

                UpdateEmptyState();
            }
            catch (Exception ex)
            {
                var dialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to load nominees: {ex.Message}",
                    CloseButtonText = "OK",
                    XamlRoot = XamlRoot
                };
                await dialog.ShowAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        private void UpdateEmptyState()
        {
            if (_nominees.Count == 0)
            {
                NomineesListView.Visibility = Visibility.Collapsed;
                EmptyStatePanel.Visibility = Visibility.Visible;
            }
            else
            {
                NomineesListView.Visibility = Visibility.Visible;
                EmptyStatePanel.Visibility = Visibility.Collapsed;
            }
        }

        private async void OnRemoveNomineeClick(object sender, RoutedEventArgs e)
        {
            if (sender is Button button && button.Tag is NomineeViewModel nomineeVM)
            {
                var confirmDialog = new ContentDialog
                {
                    Title = "Remove Nominee",
                    Content = $"Are you sure you want to remove {nomineeVM.Nominee.Name}?",
                    PrimaryButtonText = "Remove",
                    CloseButtonText = "Cancel",
                    XamlRoot = XamlRoot,
                    DefaultButton = ContentDialogButton.Close
                };

                var result = await confirmDialog.ShowAsync();
                if (result == ContentDialogResult.Primary)
                {
                    try
                    {
                        await _nomineeService.RemoveNomineeAsync(nomineeVM.Nominee.Id);
                        await LoadNomineesAsync();
                    }
                    catch (Exception ex)
                    {
                        var errorDialog = new ContentDialog
                        {
                            Title = "Error",
                            Content = $"Failed to remove nominee: {ex.Message}",
                            CloseButtonText = "OK",
                            XamlRoot = XamlRoot
                        };
                        await errorDialog.ShowAsync();
                    }
                }
            }
        }

        private void OnInviteNomineeClick(object sender, RoutedEventArgs e)
        {
            if (_vault != null)
            {
                Frame.Navigate(typeof(NomineeInvitationView), _vault);
            }
        }

        private void OnCloseClick(object sender, RoutedEventArgs e)
        {
            Frame.GoBack();
        }

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class NomineeManagementViewModel
    {
        public ObservableCollection<NomineeViewModel> Nominees { get; }
        public Vault? Vault { get; set; }

        public NomineeManagementViewModel(ObservableCollection<NomineeViewModel> nominees)
        {
            Nominees = nominees;
        }
    }

    public class NomineeViewModel : INotifyPropertyChanged
    {
        public Nominee Nominee { get; }
        public bool CanRemove => Nominee.Status != "revoked" && Nominee.Status != "inactive";

        public NomineeViewModel(Nominee nominee)
        {
            Nominee = nominee;
        }

        public event PropertyChangedEventHandler? PropertyChanged;
    }
}
