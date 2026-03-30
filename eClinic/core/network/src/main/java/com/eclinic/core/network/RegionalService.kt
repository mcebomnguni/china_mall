package com.eclinic.core.network

import com.eclinic.core.common.model.RegionalStats
import com.eclinic.core.common.model.StatsPeriod
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface RegionalService {
    @GET("api/v1/stats/region/{regionId}")
    suspend fun getRegionalStats(
        @Path("regionId") regionId: String,
        @Query("period") period: StatsPeriod
    ): RegionalStats
}
