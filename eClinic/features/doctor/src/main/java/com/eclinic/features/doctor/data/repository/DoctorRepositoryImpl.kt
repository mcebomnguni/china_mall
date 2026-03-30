package com.eclinic.features.doctor.data.repository

import com.eclinic.core.common.model.Consultation
import com.eclinic.core.common.model.DoctorDashboardResponse
import com.eclinic.core.network.ConsultationService
import com.eclinic.core.network.DoctorDashboardService
import com.eclinic.features.doctor.domain.repository.DoctorRepository
import javax.inject.Inject

class DoctorRepositoryImpl @Inject constructor(
    private val dashboardService: DoctorDashboardService,
    private val consultationService: ConsultationService
) : DoctorRepository {

    override suspend fun getDashboardData(
        doctorId: String,
        facilityId: String
    ): Result<DoctorDashboardResponse> {
        return try {
            val response = dashboardService.getDashboardData(doctorId, facilityId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun startConsultation(patientId: String): Result<Consultation> {
        return try {
            val consultation = consultationService.startConsultation(patientId)
            Result.success(consultation)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun saveConsultation(consultation: Consultation): Result<Unit> {
        return try {
            consultationService.saveConsultation(consultation)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
