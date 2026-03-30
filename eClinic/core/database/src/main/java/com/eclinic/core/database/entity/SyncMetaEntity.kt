package com.eclinic.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "sync_metadata")
data class SyncMetaEntity(
    @PrimaryKey val key: String, // e.g., "last_sync_timestamp"
    val value: Long
)
