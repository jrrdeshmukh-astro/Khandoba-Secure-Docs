using Microsoft.UI.Xaml.Controls;
using KhandobaSecureDocs.Services;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class WelcomeView : Page
    {
        private readonly AuthenticationService _authService;

        public WelcomeView()
        {
            InitializeComponent();
            _authService = App.Services.GetRequiredService<AuthenticationService>();
        }

        private async void OnSignInClick(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
        {
            await _authService.SignInWithMicrosoftAsync();
        }
    }
}
