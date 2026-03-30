package com.eclinic.features.district.domain.repository

import com.eclinic.core.common.model.DistrictStats
import com.eclinic.core.common.model.StatsPeriod

interface DistrictRepository {
    suspend fun getDistrictStats(districtId: String, period: StatsPeriod): Result<DistrictStats>
}
