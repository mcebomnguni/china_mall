package com.eclinic.core.network

import com.eclinic.core.common.model.DistrictStats
import com.eclinic.core.common.model.StatsPeriod
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface DistrictService {
    @GET("api/v1/stats/district/{districtId}")
    suspend fun getDistrictStats(
        @Path("districtId") districtId: String,
        @Query("period") period: StatsPeriod
    ): DistrictStats
}
