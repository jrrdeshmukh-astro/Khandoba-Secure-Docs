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
    public sealed partial class EmergencyApprovalView : Page, INotifyPropertyChanged
    {
        private readonly EmergencyApprovalService _emergencyService;
        private ObservableCollection<EmergencyAccessRequest> _pendingRequests = new();
        private bool _isLoading;
        private Guid? _currentUserID;

        public event PropertyChangedEventHandler? PropertyChanged;

        public EmergencyApprovalViewModel ViewModel { get; }

        public EmergencyApprovalView()
        {
            InitializeComponent();
            _emergencyService = App.Services.GetRequiredService<EmergencyApprovalService>();
            ViewModel = new EmergencyApprovalViewModel(_pendingRequests);
            
            // TODO: Get current user ID from authentication service
            // _currentUserID = authService.GetCurrentUserID();
        }

        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            await LoadPendingRequestsAsync();
        }

        private async Task LoadPendingRequestsAsync()
        {
            IsLoading = true;
            try
            {
                var requests = await _emergencyService.GetPendingRequestsAsync();
                _pendingRequests.Clear();
                foreach (var request in requests)
                {
                    _pendingRequests.Add(request);
                }

                UpdateEmptyState();
            }
            catch (Exception ex)
            {
                var dialog = new ContentDialog
                {
                    Title = "Error",
                    Content = $"Failed to load requests: {ex.Message}",
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
            if (_pendingRequests.Count == 0)
            {
                RequestsListView.Visibility = Visibility.Collapsed;
                EmptyStatePanel.Visibility = Visibility.Visible;
            }
            else
            {
                RequestsListView.Visibility = Visibility.Visible;
                EmptyStatePanel.Visibility = Visibility.Collapsed;
            }
        }

        private async void OnApproveClick(object sender, RoutedEventArgs e)
        {
            if (sender is Button button && button.Tag is EmergencyAccessRequest request)
            {
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

                var confirmDialog = new ContentDialog
                {
                    Title = "Approve Emergency Access?",
                    Content = "This will grant 24-hour access to the vault. The requester will receive an identification pass code.",
                    PrimaryButtonText = "Approve",
                    CloseButtonText = "Cancel",
                    XamlRoot = XamlRoot,
                    DefaultButton = ContentDialogButton.Close
                };

                var result = await confirmDialog.ShowAsync();
                if (result == ContentDialogResult.Primary)
                {
                    try
                    {
                        var approvedRequest = await _emergencyService.ApproveEmergencyRequestAsync(
                            request.Id,
                            _currentUserID.Value
                        );

                        // Show pass code dialog
                        var passCodeDialog = new ContentDialog
                        {
                            Title = "Emergency Access Approved",
                            Content = $"Pass Code: {approvedRequest.PassCode}\n\nShare this pass code with the requester securely. It expires in 24 hours.",
                            CloseButtonText = "OK",
                            XamlRoot = XamlRoot
                        };
                        await passCodeDialog.ShowAsync();

                        await LoadPendingRequestsAsync();
                    }
                    catch (Exception ex)
                    {
                        var errorDialog = new ContentDialog
                        {
                            Title = "Error",
                            Content = $"Failed to approve request: {ex.Message}",
                            CloseButtonText = "OK",
                            XamlRoot = XamlRoot
                        };
                        await errorDialog.ShowAsync();
                    }
                }
            }
        }

        private async void OnDenyClick(object sender, RoutedEventArgs e)
        {
            if (sender is Button button && button.Tag is EmergencyAccessRequest request)
            {
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

                var confirmDialog = new ContentDialog
                {
                    Title = "Deny Emergency Access?",
                    Content = "This will deny the emergency access request. The requester will be notified.",
                    PrimaryButtonText = "Deny",
                    CloseButtonText = "Cancel",
                    XamlRoot = XamlRoot,
                    DefaultButton = ContentDialogButton.Close
                };

                var result = await confirmDialog.ShowAsync();
                if (result == ContentDialogResult.Primary)
                {
                    try
                    {
                        await _emergencyService.DenyEmergencyRequestAsync(
                            request.Id,
                            _currentUserID.Value
                        );

                        await LoadPendingRequestsAsync();
                    }
                    catch (Exception ex)
                    {
                        var errorDialog = new ContentDialog
                        {
                            Title = "Error",
                            Content = $"Failed to deny request: {ex.Message}",
                            CloseButtonText = "OK",
                            XamlRoot = XamlRoot
                        };
                        await errorDialog.ShowAsync();
                    }
                }
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
                LoadingRing.IsActive = value;
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class EmergencyApprovalViewModel
    {
        public ObservableCollection<EmergencyAccessRequest> PendingRequests { get; }

        public EmergencyApprovalViewModel(ObservableCollection<EmergencyAccessRequest> pendingRequests)
        {
            PendingRequests = pendingRequests;
        }
    }
}
