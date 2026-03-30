package com.eclinic.features.provincial.domain.repository

import com.eclinic.core.common.model.ProvincialStats
import com.eclinic.core.common.model.StatsPeriod

interface ProvincialRepository {
    suspend fun getProvincialStats(provinceId: String, period: StatsPeriod): Result<ProvincialStats>
}
