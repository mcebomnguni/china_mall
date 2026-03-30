package com.eclinic.core.database.dao

import androidx.room.*
import com.eclinic.core.database.entity.ConsultationEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ConsultationDao {
    @Query("SELECT * FROM consultations WHERE consultationId = :id")
    suspend fun getConsultationById(id: String): ConsultationEntity?

    @Query("SELECT * FROM consultations WHERE patientId = :patientId")
    fun getConsultationsForPatient(patientId: String): Flow<List<ConsultationEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertConsultations(consultations: List<ConsultationEntity>)

    @Query("SELECT * FROM consultations WHERE syncStatus != 'SYNCED'")
    suspend fun getPendingSyncConsultations(): List<ConsultationEntity>

    @Query("UPDATE consultations SET syncStatus = 'SYNCED' WHERE consultationId IN (:ids)")
    suspend fun markAsSynced(ids: List<String>)
}
