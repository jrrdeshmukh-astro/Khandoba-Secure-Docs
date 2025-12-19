package com.khandoba.securedocs.data.repository

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
                    // Fetch user from Supabase database
                    val userData: SupabaseUser = supabaseService.fetch("users", supabaseUser.id)
                    convertFromSupabase(userData)
                } else {
                    null
                }
            } catch (e: Exception) {
                null
            }
        } else {
            // Room database
            return userDao.getUserById(UUID.randomUUID()) // TODO: Get from session
        }
    }
    
    suspend fun insertUser(user: UserEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseUser = convertToSupabase(user)
                supabaseService.insert("users", supabaseUser)
            } catch (e: Exception) {
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
                supabaseService.update("users", user.id, supabaseUser)
            } catch (e: Exception) {
                // Fallback to local storage
                userDao.updateUser(user)
            }
        } else {
            userDao.updateUser(user)
        }
    }
    
    private fun convertToSupabase(entity: UserEntity): SupabaseUser {
        return SupabaseUser(
            id = entity.id,
            google_user_id = entity.googleUserID,
            full_name = entity.fullName,
            email = entity.email,
            profile_picture_url = null, // TODO: Upload to Supabase Storage
            created_at = entity.createdAt.toISOString(),
            last_active_at = entity.lastActiveAt.toISOString(),
            is_active = entity.isActive,
            is_premium_subscriber = entity.isPremiumSubscriber,
            subscription_expiry_date = entity.subscriptionExpiryDate?.toISOString(),
            updated_at = Date().toISOString()
        )
    }
    
    private fun convertFromSupabase(supabase: SupabaseUser): UserEntity {
        return UserEntity(
            id = supabase.id,
            googleUserID = supabase.google_user_id,
            fullName = supabase.full_name,
            email = supabase.email,
            profilePictureData = null, // TODO: Download from Supabase Storage
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
