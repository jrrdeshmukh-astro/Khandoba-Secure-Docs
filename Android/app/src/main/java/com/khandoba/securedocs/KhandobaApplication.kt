package com.khandoba.securedocs

import android.app.Application
import androidx.room.Room
import com.khandoba.securedocs.data.database.KhandobaDatabase

class KhandobaApplication : Application() {
    
    val database: KhandobaDatabase by lazy {
        Room.databaseBuilder(
            applicationContext,
            KhandobaDatabase::class.java,
            "khandoba_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }
    
    override fun onCreate() {
        super.onCreate()
        // Initialize app-wide services here
    }
}
