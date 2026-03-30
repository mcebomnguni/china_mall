package com.eclinic.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.eclinic.core.database.entity.SyncMetaEntity

@Dao
interface SyncMetaDao {
    @Query("SELECT value FROM sync_metadata WHERE `key` = :key")
    suspend fun getValue(key: String): Long?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(syncMeta: SyncMetaEntity)
}
