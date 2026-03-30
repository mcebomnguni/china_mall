package com.eclinic.features.national.domain.repository

import com.eclinic.core.common.model.NationalStats
import com.eclinic.core.common.model.StatsPeriod

interface NationalRepository {
    suspend fun getNationalStats(period: StatsPeriod): Result<NationalStats>
}
