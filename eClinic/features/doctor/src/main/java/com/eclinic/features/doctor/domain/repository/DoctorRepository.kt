package com.eclinic.features.doctor.domain.repository

import com.eclinic.core.common.model.Consultation
import com.eclinic.core.common.model.DoctorDashboardResponse

interface DoctorRepository {
    suspend fun getDashboardData(doctorId: String, facilityId: String): Result<DoctorDashboardResponse>
    suspend fun startConsultation(patientId: String): Result<Consultation>
    suspend fun saveConsultation(consultation: Consultation): Result<Unit>
}
