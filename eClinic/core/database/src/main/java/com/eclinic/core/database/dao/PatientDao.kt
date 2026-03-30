package com.eclinic.core.database.dao

import androidx.room.*
import com.eclinic.core.database.entity.PatientEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PatientDao {
    @Query("SELECT * FROM patients WHERE patientId = :id")
    suspend fun getPatientById(id: String): PatientEntity?

    @Query("SELECT * FROM patients WHERE facilityId = :facilityId")
    fun getPatientsByFacility(facilityId: String): Flow<List<PatientEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPatients(patients: List<PatientEntity>)

    @Update
    suspend fun updatePatient(patient: PatientEntity)

    @Query("SELECT * FROM patients WHERE isSyncPending = 1")
    suspend fun getPendingSyncPatients(): List<PatientEntity>

    @Query("UPDATE patients SET isSyncPending = 0 WHERE patientId IN (:ids)")
    suspend fun markAsSynced(ids: List<String>)
}
