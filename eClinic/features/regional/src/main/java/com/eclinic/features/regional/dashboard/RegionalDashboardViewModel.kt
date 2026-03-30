package com.eclinic.features.regional.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.features.regional.domain.repository.RegionalRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RegionalDashboardViewModel @Inject constructor(
    private val repository: RegionalRepository
) : ViewModel() {

    private val _state = MutableStateFlow<RegionalDashboardState>(RegionalDashboardState.Loading)
    val state: StateFlow<RegionalDashboardState> = _state.asStateFlow()

    private var currentRegionId: String = "reg-123" // Placeholder
    private var currentPeriod: StatsPeriod = StatsPeriod.MONTHLY

    init {
        loadStats()
    }

    fun onIntent(intent: RegionalDashboardIntent) {
        when (intent) {
            is RegionalDashboardIntent.LoadStats -> {
                currentRegionId = intent.regionId
                currentPeriod = intent.period
                loadStats()
            }
            is RegionalDashboardIntent.ChangePeriod -> {
                currentPeriod = intent.period
                loadStats()
            }
            RegionalDashboardIntent.Refresh -> loadStats()
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            _state.value = RegionalDashboardState.Loading
            repository.getRegionalStats(currentRegionId, currentPeriod)
                .onSuccess { stats ->
                    _state.value = RegionalDashboardState.Success(stats, currentPeriod)
                }
                .onFailure { error ->
                    _state.value = RegionalDashboardState.Error(error.message ?: "Failed to load regional statistics")
                }
        }
    }
}
