package com.eclinic.features.provincial.dashboard

import com.eclinic.core.common.model.ProvincialStats
import com.eclinic.core.common.model.StatsPeriod

sealed interface ProvincialDashboardState {
    data object Loading : ProvincialDashboardState
    data class Success(
        val stats: ProvincialStats,
        val selectedPeriod: StatsPeriod
    ) : ProvincialDashboardState
    data class Error(val message: String) : ProvincialDashboardState
}

sealed interface ProvincialDashboardIntent {
    data class LoadStats(val provinceId: String, val period: StatsPeriod) : ProvincialDashboardIntent
    data class ChangePeriod(val period: StatsPeriod) : ProvincialDashboardIntent
    data object Refresh : ProvincialDashboardIntent
}
