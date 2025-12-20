package com.khandoba.securedocs.data.repository

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.dao.UserDao
import com.khandoba.securedocs.data.entity.UserEntity
import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.data.supabase.SupabaseUser
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Date
import java.util.UUID

class UserRepository(
    private val userDao: UserDao,
    private val supabaseService: SupabaseService?
) {
    fun getUserById(id: UUID): Flow<UserEntity?> {
        return userDao.getAllUsers().map { users ->
            users.firstOrNull { it.id == id }
        }
    }
    
    fun getUserByGoogleID(googleUserID: String): Flow<UserEntity?> {
        return userDao.getAllUsers().map { users ->
            users.firstOrNull { it.googleUserID == googleUserID }
        }
    }
    
    suspend fun getCurrentUser(): UserEntity? {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            return try {
                val supabaseUser = supabaseService.getCurrentUser()
                if (supabaseUser != null) {
                    // Fetch user from Supabase database using user ID from auth
                    val userId = UUID.fromString(supabaseUser.id)
                    val userData: SupabaseUser = supabaseService.fetch("users", userId)
                    val entity = convertFromSupabase(userData) // Downloads profile picture if available
                    // Cache in Room
                    userDao.insertUser(entity)
                    entity
                } else {
                    null
                }
            } catch (e: Exception) {
                android.util.Log.e("UserRepository", "Error fetching user from Supabase: ${e.message}")
                null
            }
        } else {
            // Room database - try to get from local storage if available
            // Note: In local-only mode, user session management would be handled differently
            return null
        }
    }
    
    suspend fun insertUser(user: UserEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseUser = convertToSupabase(user)
                val inserted = supabaseService.insert("users", supabaseUser)
                // Update local cache with inserted data (includes profile_picture_url)
                val updatedEntity = convertFromSupabase(inserted)
                userDao.insertUser(updatedEntity)
            } catch (e: Exception) {
                Log.e("UserRepository", "Failed to insert user to Supabase: ${e.message}")
                // Fallback to local storage
                userDao.insertUser(user)
            }
        } else {
            userDao.insertUser(user)
        }
    }
    
    suspend fun updateUser(user: UserEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseUser = convertToSupabase(user)
                val updated = supabaseService.update("users", user.id, supabaseUser)
                // Update local cache with updated data (includes profile_picture_url)
                val updatedEntity = convertFromSupabase(updated)
                userDao.updateUser(updatedEntity)
            } catch (e: Exception) {
                Log.e("UserRepository", "Failed to update user in Supabase: ${e.message}")
                // Fallback to local storage
                userDao.updateUser(user)
            }
        } else {
            userDao.updateUser(user)
        }
    }
    
    private suspend fun convertToSupabase(entity: UserEntity): SupabaseUser {
        // Upload profile picture to Supabase Storage if available
        var profilePictureUrl: String? = null
        if (entity.profilePictureData != null && supabaseService != null) {
            try {
                val filePath = "${entity.id}/profile_picture.jpg"
                supabaseService.uploadFile(
                    bucket = AppConfig.PROFILE_PICTURES_BUCKET,
                    path = filePath,
                    data = entity.profilePictureData
                )
                profilePictureUrl = "${AppConfig.STORAGE_PUBLIC_URL}/${AppConfig.PROFILE_PICTURES_BUCKET}/$filePath"
                Log.d("UserRepository", "✅ Uploaded profile picture to storage: $filePath")
            } catch (e: Exception) {
                Log.e("UserRepository", "❌ Failed to upload profile picture: ${e.message}")
                // Continue without profile picture URL
            }
        }
        
        return SupabaseUser(
            id = entity.id,
            google_user_id = entity.googleUserID,
            full_name = entity.fullName,
            email = entity.email,
            profile_picture_url = profilePictureUrl,
            created_at = entity.createdAt.toISOString(),
            last_active_at = entity.lastActiveAt.toISOString(),
            is_active = entity.isActive,
            is_premium_subscriber = entity.isPremiumSubscriber,
            subscription_expiry_date = entity.subscriptionExpiryDate?.toISOString(),
            updated_at = Date().toISOString()
        )
    }
    
    private suspend fun convertFromSupabase(supabase: SupabaseUser): UserEntity {
        // Download profile picture from Supabase Storage if URL is available
        var profilePictureData: ByteArray? = null
        if (supabase.profile_picture_url != null && supabaseService != null) {
            try {
                // Extract file path from URL (format: .../profile-pictures/{userId}/profile_picture.jpg)
                val urlParts = supabase.profile_picture_url.split("/")
                val filePathIndex = urlParts.indexOfLast { it == AppConfig.PROFILE_PICTURES_BUCKET }
                if (filePathIndex >= 0 && filePathIndex < urlParts.size - 1) {
                    val filePath = urlParts.subList(filePathIndex + 1, urlParts.size).joinToString("/")
                    profilePictureData = supabaseService.downloadFile(
                        bucket = AppConfig.PROFILE_PICTURES_BUCKET,
                        path = filePath
                    )
                    Log.d("UserRepository", "✅ Downloaded profile picture from storage: $filePath")
                }
            } catch (e: Exception) {
                Log.e("UserRepository", "❌ Failed to download profile picture: ${e.message}")
                // Continue without profile picture data
            }
        }
        
        return UserEntity(
            id = supabase.id,
            googleUserID = supabase.google_user_id,
            fullName = supabase.full_name,
            email = supabase.email,
            profilePictureData = profilePictureData,
            createdAt = supabase.created_at.toDate(),
            lastActiveAt = supabase.last_active_at.toDate(),
            isActive = supabase.is_active,
            isPremiumSubscriber = supabase.is_premium_subscriber,
            subscriptionExpiryDate = supabase.subscription_expiry_date?.toDate()
        )
    }
    
    private fun Date.toISOString(): String {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(this)
    }
    
    private fun String.toDate(): Date {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.parse(this) ?: Date()
    }
}

