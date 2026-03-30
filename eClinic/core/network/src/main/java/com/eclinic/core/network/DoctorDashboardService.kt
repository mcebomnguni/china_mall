package com.eclinic.core.network

import com.eclinic.core.common.model.DoctorDashboardResponse
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface DoctorDashboardService {
    @GET("api/v1/doctor/dashboard/{doctorId}")
    suspend fun getDashboardData(
        @Path("doctorId") doctorId: String,
        @Query("facilityId") facilityId: String
    ): DoctorDashboardResponse
}
