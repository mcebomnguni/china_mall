package com.eclinic.core.network

import com.eclinic.core.common.model.FacilityStats
import com.eclinic.core.common.model.StatsPeriod
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface ManagerService {
    @GET("api/v1/stats/facility/{facilityId}")
    suspend fun getFacilityStats(
        @Path("facilityId") facilityId: String,
        @Query("period") period: StatsPeriod
    ): FacilityStats
}
