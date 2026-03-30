package com.eclinic.features.sync.data.repository

import com.eclinic.core.database.dao.ConsultationDao
import com.eclinic.core.database.dao.PatientDao
import com.eclinic.core.database.dao.SyncMetaDao
import com.eclinic.core.database.dao.VitalsDao
import com.eclinic.core.database.entity.SyncMetaEntity
import com.eclinic.core.network.SyncApi
import com.eclinic.core.network.SyncPushRequest
import com.eclinic.features.sync.domain.repository.SyncRepository
import javax.inject.Inject

class SyncRepositoryImpl @Inject constructor(
    private val patientDao: PatientDao,
    private val consultationDao: ConsultationDao,
    private val vitalsDao: VitalsDao,
    private val syncMetaDao: SyncMetaDao,
    private val syncApi: SyncApi
) : SyncRepository {

    override suspend fun sync(): Result<Unit> {
        return try {
            // 1. Push local pending changes
            val pendingPatients = patientDao.getPendingSyncPatients()
            val pendingConsultations = consultationDao.getPendingSyncConsultations()
            val pendingVitals = vitalsDao.getPendingSyncVitals()

            if (pendingPatients.isNotEmpty() || pendingConsultations.isNotEmpty() || pendingVitals.isNotEmpty()) {
                val pushRequest = SyncPushRequest(
                    patients = pendingPatients,
                    consultations = pendingConsultations,
                    vitals = pendingVitals
                )
                val pushResponse = syncApi.push(pushRequest)
                
                // Mark as synced based on accepted IDs
                // Simplified: assuming all were accepted for MVP
                patientDao.markAsSynced(pendingPatients.map { it.patientId })
                consultationDao.markAsSynced(pendingConsultations.map { it.consultationId })
                vitalsDao.markAsSynced(pendingVitals.map { it.vitalsId })
            }

            // 2. Pull remote changes
            val lastSyncTime = syncMetaDao.getValue("last_sync_timestamp") ?: 0L
            val pullResponse = syncApi.pull(lastSyncTime)

            // Apply remote changes
            if (pullResponse.patients.isNotEmpty()) {
                patientDao.insertPatients(pullResponse.patients)
            }
            if (pullResponse.consultations.isNotEmpty()) {
                consultationDao.insertConsultations(pullResponse.consultations)
            }
            if (pullResponse.vitals.isNotEmpty()) {
                vitalsDao.insertVitals(pullResponse.vitals)
            }

            // Update last sync time
            syncMetaDao.insert(SyncMetaEntity("last_sync_timestamp", pullResponse.serverTime))

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
