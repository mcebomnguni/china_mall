package com.eclinic.features.district.dashboard

import com.eclinic.core.common.model.DistrictStats
import com.eclinic.core.common.model.StatsPeriod

sealed interface DistrictDashboardState {
    object Loading : DistrictDashboardState
    data class Success(
        val stats: DistrictStats,
        val selectedPeriod: StatsPeriod
    ) : DistrictDashboardState
    data class Error(val message: String) : DistrictDashboardState
}

sealed interface DistrictDashboardIntent {
    data class LoadStats(val districtId: String, val period: StatsPeriod) : DistrictDashboardIntent
    data class ChangePeriod(val period: StatsPeriod) : DistrictDashboardIntent
    object Refresh : DistrictDashboardIntent
}
