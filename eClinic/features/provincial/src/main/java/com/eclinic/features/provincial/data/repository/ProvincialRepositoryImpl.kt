package com.eclinic.features.provincial.data.repository

import com.eclinic.core.common.model.ProvincialStats
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.core.network.ProvincialService
import com.eclinic.features.provincial.domain.repository.ProvincialRepository
import javax.inject.Inject

class ProvincialRepositoryImpl @Inject constructor(
    private val provincialService: ProvincialService
) : ProvincialRepository {

    override suspend fun getProvincialStats(
        provinceId: String,
        period: StatsPeriod
    ): Result<ProvincialStats> {
        return try {
            val stats = provincialService.getProvincialStats(provinceId, period)
            Result.success(stats)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
