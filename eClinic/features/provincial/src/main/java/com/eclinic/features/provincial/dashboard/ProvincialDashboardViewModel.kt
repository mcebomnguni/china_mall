package com.eclinic.features.provincial.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.features.provincial.domain.repository.ProvincialRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProvincialDashboardViewModel @Inject constructor(
    private val repository: ProvincialRepository
) : ViewModel() {

    private val _state = MutableStateFlow<ProvincialDashboardState>(ProvincialDashboardState.Loading)
    val state: StateFlow<ProvincialDashboardState> = _state.asStateFlow()

    private var currentProvinceId: String = "prov-123" // Placeholder
    private var currentPeriod: StatsPeriod = StatsPeriod.MONTHLY

    init {
        loadStats()
    }

    fun onIntent(intent: ProvincialDashboardIntent) {
        when (intent) {
            is ProvincialDashboardIntent.LoadStats -> {
                currentProvinceId = intent.provinceId
                currentPeriod = intent.period
                loadStats()
            }
            is ProvincialDashboardIntent.ChangePeriod -> {
                currentPeriod = intent.period
                loadStats()
            }
            ProvincialDashboardIntent.Refresh -> loadStats()
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            _state.value = ProvincialDashboardState.Loading
            repository.getProvincialStats(currentProvinceId, currentPeriod)
                .onSuccess { stats ->
                    _state.value = ProvincialDashboardState.Success(stats, currentPeriod)
                }
                .onFailure { error ->
                    _state.value = ProvincialDashboardState.Error(error.message ?: "Failed to load provincial statistics")
                }
        }
    }
}
