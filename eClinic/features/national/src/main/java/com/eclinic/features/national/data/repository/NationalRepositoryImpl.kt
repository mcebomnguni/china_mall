package com.eclinic.features.national.data.repository

import com.eclinic.core.common.model.NationalStats
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.core.network.NationalService
import com.eclinic.features.national.domain.repository.NationalRepository
import javax.inject.Inject

class NationalRepositoryImpl @Inject constructor(
    private val nationalService: NationalService
) : NationalRepository {

    override suspend fun getNationalStats(period: StatsPeriod): Result<NationalStats> {
        return try {
            val stats = nationalService.getNationalStats(period)
            Result.success(stats)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
