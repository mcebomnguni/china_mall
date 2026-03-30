package com.eclinic.features.national.dashboard

import com.eclinic.core.common.model.NationalStats
import com.eclinic.core.common.model.StatsPeriod

sealed interface NationalDashboardState {
    data object Loading : NationalDashboardState
    data class Success(
        val stats: NationalStats,
        val selectedPeriod: StatsPeriod
    ) : NationalDashboardState
    data class Error(val message: String) : NationalDashboardState
}

sealed interface NationalDashboardIntent {
    data class LoadStats(val period: StatsPeriod) : NationalDashboardIntent
    data class ChangePeriod(val period: StatsPeriod) : NationalDashboardIntent
    data object Refresh : NationalDashboardIntent
}
