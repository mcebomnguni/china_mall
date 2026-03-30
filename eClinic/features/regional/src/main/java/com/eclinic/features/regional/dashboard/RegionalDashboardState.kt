package com.eclinic.features.regional.dashboard

import com.eclinic.core.common.model.RegionalStats
import com.eclinic.core.common.model.StatsPeriod

sealed interface RegionalDashboardState {
    data object Loading : RegionalDashboardState
    data class Success(
        val stats: RegionalStats,
        val selectedPeriod: StatsPeriod
    ) : RegionalDashboardState
    data class Error(val message: String) : RegionalDashboardState
}

sealed interface RegionalDashboardIntent {
    data class LoadStats(val regionId: String, val period: StatsPeriod) : RegionalDashboardIntent
    data class ChangePeriod(val period: StatsPeriod) : RegionalDashboardIntent
    data object Refresh : RegionalDashboardIntent
}
