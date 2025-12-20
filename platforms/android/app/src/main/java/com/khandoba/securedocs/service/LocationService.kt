package com.khandoba.securedocs.service

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

class LocationService(private val context: Context) {
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    
    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> = _currentLocation.asStateFlow()
    
    private val _isLocationEnabled = MutableStateFlow(false)
    val isLocationEnabled: StateFlow<Boolean> = _isLocationEnabled.asStateFlow()
    
    suspend fun getCurrentLocation(): Location? {
        if (!hasLocationPermission()) {
            Log.w("LocationService", "Location permission not granted")
            return null
        }
        
        return try {
            val location = fusedLocationClient.lastLocation.await()
            _currentLocation.value = location
            location
        } catch (e: Exception) {
            Log.e("LocationService", "Error getting location: ${e.message}")
            null
        }
    }
    
    suspend fun requestLocationUpdates(
        onLocationUpdate: (Location) -> Unit
    ) {
        if (!hasLocationPermission()) {
            Log.w("LocationService", "Location permission not granted")
            return
        }
        
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000L // 10 seconds
        ).build()
        
        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    _currentLocation.value = location
                    onLocationUpdate(location)
                }
            }
        }
        
        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                context.mainLooper
            )
            _isLocationEnabled.value = true
        } catch (e: Exception) {
            Log.e("LocationService", "Error requesting location updates: ${e.message}")
        }
    }
    
    fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(object : LocationCallback() {})
        _isLocationEnabled.value = false
    }
    
    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
}
