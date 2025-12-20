using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;

namespace KhandobaSecureDocs.ViewModels
{
    public class VaultViewModel : INotifyPropertyChanged
    {
        private readonly VaultService _vaultService;
        private readonly AuthenticationService _authService;
        private ObservableCollection<Vault> _vaults = new();
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public ObservableCollection<Vault> Vaults
        {
            get => _vaults;
            private set
            {
                _vaults = value;
                OnPropertyChanged();
            }
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

        public VaultViewModel(VaultService vaultService, AuthenticationService authService)
        {
            _vaultService = vaultService;
            _authService = authService;

            _vaultService.PropertyChanged += OnVaultServiceChanged;
            LoadVaultsAsync();
        }

        private void OnVaultServiceChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(VaultService.Vaults))
            {
                Vaults = new ObservableCollection<Vault>(_vaultService.Vaults);
            }
        }

        private async void LoadVaultsAsync()
        {
            if (_authService.CurrentUser == null) return;

            IsLoading = true;
            try
            {
                await _vaultService.LoadVaultsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task CreateVaultAsync(string name, string? description, string keyType)
        {
            if (_authService.CurrentUser == null) return;

            IsLoading = true;
            try
            {
                await _vaultService.CreateVaultAsync(name, description, keyType);
                await LoadVaultsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task OpenVaultAsync(Vault vault)
        {
            IsLoading = true;
            try
            {
                await _vaultService.OpenVaultAsync(vault);
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task CloseVaultAsync(Vault vault)
        {
            IsLoading = true;
            try
            {
                await _vaultService.CloseVaultAsync(vault);
            }
            finally
            {
                IsLoading = false;
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
