package com.eclinic.features.district.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.features.district.domain.repository.DistrictRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DistrictDashboardViewModel @Inject constructor(
    private val repository: DistrictRepository
) : ViewModel() {

    private val _state = MutableStateFlow<DistrictDashboardState>(DistrictDashboardState.Loading)
    val state: StateFlow<DistrictDashboardState> = _state.asStateFlow()

    private var currentDistrictId: String = "dist-123" // Placeholder
    private var currentPeriod: StatsPeriod = StatsPeriod.MONTHLY

    init {
        loadStats()
    }

    fun onIntent(intent: DistrictDashboardIntent) {
        when (intent) {
            is DistrictDashboardIntent.LoadStats -> {
                currentDistrictId = intent.districtId
                currentPeriod = intent.period
                loadStats()
            }
            is DistrictDashboardIntent.ChangePeriod -> {
                currentPeriod = intent.period
                loadStats()
            }
            DistrictDashboardIntent.Refresh -> loadStats()
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            _state.value = DistrictDashboardState.Loading
            repository.getDistrictStats(currentDistrictId, currentPeriod)
                .onSuccess { stats ->
                    _state.value = DistrictDashboardState.Success(stats, currentPeriod)
                }
                .onFailure { error ->
                    _state.value = DistrictDashboardState.Error(error.message ?: "Failed to load district statistics")
                }
        }
    }
}
