package com.khandoba.securedocs.data.database

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.khandoba.securedocs.data.dao.*
import com.khandoba.securedocs.data.entity.*

@Database(
    entities = [
        UserEntity::class,
        UserRoleEntity::class,
        VaultEntity::class,
        VaultSessionEntity::class,
        VaultAccessLogEntity::class,
        DocumentEntity::class,
        DocumentVersionEntity::class,
        NomineeEntity::class,
        DualKeyRequestEntity::class,
        EmergencyAccessRequestEntity::class,
        VaultTransferRequestEntity::class,
        VaultAccessRequestEntity::class,
        ChatMessageEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class KhandobaDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun userRoleDao(): UserRoleDao
    abstract fun vaultDao(): VaultDao
    abstract fun documentDao(): DocumentDao
    abstract fun vaultSessionDao(): VaultSessionDao
    abstract fun vaultAccessLogDao(): VaultAccessLogDao
    abstract fun nomineeDao(): NomineeDao
    abstract fun dualKeyRequestDao(): DualKeyRequestDao
    abstract fun chatMessageDao(): ChatMessageDao
}
