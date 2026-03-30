package com.eclinic.features.regional.domain.repository

import com.eclinic.core.common.model.RegionalStats
import com.eclinic.core.common.model.StatsPeriod

interface RegionalRepository {
    suspend fun getRegionalStats(regionId: String, period: StatsPeriod): Result<RegionalStats>
}
