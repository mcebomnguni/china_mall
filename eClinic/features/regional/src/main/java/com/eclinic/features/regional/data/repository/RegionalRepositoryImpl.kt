package com.eclinic.features.regional.data.repository

import com.eclinic.core.common.model.RegionalStats
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.core.network.RegionalService
import com.eclinic.features.regional.domain.repository.RegionalRepository
import javax.inject.Inject

class RegionalRepositoryImpl @Inject constructor(
    private val regionalService: RegionalService
) : RegionalRepository {

    override suspend fun getRegionalStats(
        regionId: String,
        period: StatsPeriod
    ): Result<RegionalStats> {
        return try {
            val stats = regionalService.getRegionalStats(regionId, period)
            Result.success(stats)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
