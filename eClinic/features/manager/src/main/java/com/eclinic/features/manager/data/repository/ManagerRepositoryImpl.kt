package com.eclinic.features.manager.data.repository

import com.eclinic.core.common.model.FacilityStats
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.core.network.ManagerService
import com.eclinic.features.manager.domain.repository.ManagerRepository
import javax.inject.Inject

class ManagerRepositoryImpl @Inject constructor(
    private val managerService: ManagerService
) : ManagerRepository {

    override suspend fun getFacilityStats(
        facilityId: String,
        period: StatsPeriod
    ): Result<FacilityStats> {
        return try {
            val stats = managerService.getFacilityStats(facilityId, period)
            Result.success(stats)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
