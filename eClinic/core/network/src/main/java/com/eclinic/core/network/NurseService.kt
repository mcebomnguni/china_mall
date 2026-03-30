package com.eclinic.core.network

import com.eclinic.core.common.model.NurseDashboardData
import com.eclinic.core.common.model.Vitals
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path

interface NurseService {
    @GET("api/v1/nurse/dashboard/{nurseId}")
    suspend fun getNurseDashboard(@Path("nurseId") nurseId: String): NurseDashboardData

    @POST("api/v1/nurse/vitals")
    suspend fun recordVitals(@Body vitals: Vitals)
}
