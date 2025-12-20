using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml;
using KhandobaSecureDocs.Services;
using KhandobaSecureDocs.Views;

namespace KhandobaSecureDocs
{
    public sealed partial class MainWindow : Window
    {
        private readonly AuthenticationService _authService;

        public MainWindow()
        {
            InitializeComponent();
            _authService = App.Services.GetRequiredService<AuthenticationService>();

            _authService.PropertyChanged += OnAuthStateChanged;
            NavigateToInitialView();
        }

        private void NavigateToInitialView()
        {
            if (_authService.IsAuthenticated)
            {
                ContentFrame.Navigate(typeof(VaultListView));
            }
            else
            {
                ContentFrame.Navigate(typeof(WelcomeView));
            }
        }

        private void OnAuthStateChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(AuthenticationService.IsAuthenticated))
            {
                NavigateToInitialView();
            }
        }
    }
}
