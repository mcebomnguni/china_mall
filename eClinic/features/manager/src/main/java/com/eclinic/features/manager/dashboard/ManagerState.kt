package com.eclinic.features.manager.dashboard

import com.eclinic.core.common.model.FacilityStats
import com.eclinic.core.common.model.StatsPeriod

sealed interface ManagerState {
    object Loading : ManagerState
    data class Success(
        val stats: FacilityStats,
        val selectedPeriod: StatsPeriod
    ) : ManagerState
    data class Error(val message: String) : ManagerState
}

sealed interface ManagerIntent {
    data class LoadStats(val facilityId: String, val period: StatsPeriod) : ManagerIntent
    data class ChangePeriod(val period: StatsPeriod) : ManagerIntent
    object Refresh : ManagerIntent
}
