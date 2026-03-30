package com.eclinic.features.patient.domain.repository

import com.eclinic.core.common.model.MedicalRecord
import com.eclinic.core.common.model.PatientDashboardData

interface PatientRepository {
    suspend fun getDashboardData(patientId: String): Result<PatientDashboardData>
    suspend fun getMedicalRecords(patientId: String): Result<List<MedicalRecord>>
}
