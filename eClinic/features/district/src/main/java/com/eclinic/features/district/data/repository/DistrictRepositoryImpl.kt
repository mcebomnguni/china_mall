package com.eclinic.features.district.data.repository

import com.eclinic.core.common.model.DistrictStats
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.core.network.DistrictService
import com.eclinic.features.district.domain.repository.DistrictRepository
import javax.inject.Inject

class DistrictRepositoryImpl @Inject constructor(
    private val districtService: DistrictService
) : DistrictRepository {

    override suspend fun getDistrictStats(
        districtId: String,
        period: StatsPeriod
    ): Result<DistrictStats> {
        return try {
            val stats = districtService.getDistrictStats(districtId, period)
            Result.success(stats)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
