package com.eclinic.features.doctor.data.repository

import com.eclinic.core.common.model.DoctorDashboardResponse
import com.eclinic.core.network.DoctorDashboardService
import com.eclinic.features.doctor.domain.repository.DoctorDashboardRepository
import javax.inject.Inject

class DoctorDashboardRepositoryImpl @Inject constructor(
    private val service: DoctorDashboardService
) : DoctorDashboardRepository {

    override suspend fun getDashboardData(
        doctorId: String,
        facilityId: String
    ): Result<DoctorDashboardResponse> {
        return try {
            val response = service.getDashboardData(doctorId, facilityId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
