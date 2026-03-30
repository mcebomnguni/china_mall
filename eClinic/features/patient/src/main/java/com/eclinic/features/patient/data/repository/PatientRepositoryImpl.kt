package com.eclinic.features.patient.data.repository

import com.eclinic.core.common.model.MedicalRecord
import com.eclinic.core.common.model.PatientDashboardData
import com.eclinic.core.network.PatientService
import com.eclinic.features.patient.domain.repository.PatientRepository
import javax.inject.Inject

class PatientRepositoryImpl @Inject constructor(
    private val patientService: PatientService
) : PatientRepository {

    override suspend fun getDashboardData(patientId: String): Result<PatientDashboardData> {
        return try {
            val data = patientService.getDashboardData(patientId)
            Result.success(data)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMedicalRecords(patientId: String): Result<List<MedicalRecord>> {
        return try {
            val records = patientService.getMedicalRecords(patientId)
            Result.success(records)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
