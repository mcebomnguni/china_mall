package com.eclinic.features.doctor.domain.repository

import com.eclinic.core.common.model.DoctorDashboardResponse

interface DoctorDashboardRepository {
    suspend fun getDashboardData(doctorId: String, facilityId: String): Result<DoctorDashboardResponse>
}
