using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml;
using KhandobaSecureDocs.Services;
using KhandobaSecureDocs.ViewModels;
using System;
using System.Threading.Tasks;

namespace KhandobaSecureDocs
{
    public partial class App : Application
    {
        private Window? _mainWindow;
        public static IServiceProvider Services { get; private set; } = null!;

        public App()
        {
            InitializeComponent();
        }

        protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
        {
            // Configure dependency injection
            var services = new ServiceCollection();
            ConfigureServices(services);
            Services = services.BuildServiceProvider();

            // Initialize Supabase
            var supabaseService = Services.GetRequiredService<SupabaseService>();
            Task.Run(async () => await supabaseService.ConfigureAsync());

            _mainWindow = new MainWindow();
            _mainWindow.Activate();
        }

        public Window? GetActiveWindow()
        {
            return _mainWindow;
        }

        private void ConfigureServices(IServiceCollection services)
        {
            // Services
            services.AddSingleton<SupabaseService>();
            services.AddSingleton<EncryptionService>();
            services.AddSingleton<LocationService>();
            services.AddSingleton<DocumentIndexingService>();
            services.AddSingleton<FormalLogicEngine>();
            services.AddSingleton<InferenceEngine>();
            services.AddSingleton<VideoRecordingService>();
            services.AddSingleton<VoiceRecordingService>();
            services.AddSingleton<DocumentService>();
            services.AddSingleton<AuthenticationService>();
            services.AddSingleton<VaultService>();
            services.AddSingleton<NomineeService>();
            services.AddSingleton<EmergencyApprovalService>();
            services.AddSingleton<BroadcastVaultService>();
            services.AddSingleton<VaultTransferService>();

            // ViewModels
            services.AddTransient<VaultViewModel>();
        }
    }
}
