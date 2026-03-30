package com.eclinic.features.manager.domain.repository

import com.eclinic.core.common.model.FacilityStats
import com.eclinic.core.common.model.StatsPeriod

interface ManagerRepository {
    suspend fun getFacilityStats(facilityId: String, period: StatsPeriod): Result<FacilityStats>
}
