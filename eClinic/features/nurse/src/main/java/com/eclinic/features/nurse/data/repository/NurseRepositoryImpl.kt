package com.eclinic.features.nurse.data.repository

import com.eclinic.core.common.model.NurseDashboardData
import com.eclinic.core.common.model.Vitals
import com.eclinic.core.network.NurseService
import com.eclinic.features.nurse.domain.repository.NurseRepository
import javax.inject.Inject

class NurseRepositoryImpl @Inject constructor(
    private val nurseService: NurseService
) : NurseRepository {

    override suspend fun getNurseDashboard(nurseId: String): Result<NurseDashboardData> {
        return try {
            val response = nurseService.getNurseDashboard(nurseId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun recordVitals(vitals: Vitals): Result<Unit> {
        return try {
            nurseService.recordVitals(vitals)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
