package com.eclinic.core.database.dao

import androidx.room.*
import com.eclinic.core.database.entity.VitalsEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface VitalsDao {
    @Query("SELECT * FROM vitals WHERE patientId = :patientId ORDER BY recordedAt DESC")
    fun getVitalsForPatient(patientId: String): Flow<List<VitalsEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVitals(vitals: List<VitalsEntity>)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVital(vital: VitalsEntity)

    @Query("SELECT * FROM vitals WHERE syncStatus != 'SYNCED'")
    suspend fun getPendingSyncVitals(): List<VitalsEntity>

    @Query("UPDATE vitals SET syncStatus = 'SYNCED' WHERE vitalsId IN (:ids)")
    suspend fun markAsSynced(ids: List<String>)
}
