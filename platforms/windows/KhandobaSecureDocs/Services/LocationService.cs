using System;
using System.Threading.Tasks;
using Windows.Devices.Geolocation;

namespace KhandobaSecureDocs.Services
{
    public class LocationService
    {
        private Geolocator? _geolocator;
        private Geoposition? _currentLocation;

        public Geoposition? CurrentLocation => _currentLocation;

        public async Task<Geoposition?> GetCurrentLocationAsync()
        {
            try
            {
                // Request location permission
                var accessStatus = await Geolocator.RequestAccessAsync();
                if (accessStatus != GeolocationAccessStatus.Allowed)
                {
                    return null;
                }

                _geolocator = new Geolocator
                {
                    DesiredAccuracy = PositionAccuracy.High
                };

                _currentLocation = await _geolocator.GetGeopositionAsync();
                return _currentLocation;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to get location: {ex.Message}");
                return null;
            }
        }

        public async Task<bool> RequestLocationPermissionAsync()
        {
            var accessStatus = await Geolocator.RequestAccessAsync();
            return accessStatus == GeolocationAccessStatus.Allowed;
        }
    }
}

