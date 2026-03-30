package com.eclinic.core.network

import com.eclinic.core.common.model.NationalStats
import com.eclinic.core.common.model.StatsPeriod
import retrofit2.http.GET
import retrofit2.http.Query

interface NationalService {
    @GET("api/v1/stats/national")
    suspend fun getNationalStats(
        @Query("period") period: StatsPeriod
    ): NationalStats
}
