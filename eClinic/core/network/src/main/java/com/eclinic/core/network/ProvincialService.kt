package com.eclinic.core.network

import com.eclinic.core.common.model.ProvincialStats
import com.eclinic.core.common.model.StatsPeriod
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface ProvincialService {
    @GET("api/v1/stats/province/{provinceId}")
    suspend fun getProvincialStats(
        @Path("provinceId") provinceId: String,
        @Query("period") period: StatsPeriod
    ): ProvincialStats
}
