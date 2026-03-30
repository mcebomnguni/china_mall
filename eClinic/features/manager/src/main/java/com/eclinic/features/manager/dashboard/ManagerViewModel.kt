package com.eclinic.features.manager.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.features.manager.domain.repository.ManagerRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ManagerViewModel @Inject constructor(
    private val repository: ManagerRepository
) : ViewModel() {

    private val _state = MutableStateFlow<ManagerState>(ManagerState.Loading)
    val state: StateFlow<ManagerState> = _state.asStateFlow()

    private var currentFacilityId: String = "fac-456" // Default for MVP
    private var currentPeriod: StatsPeriod = StatsPeriod.DAILY

    init {
        loadStats()
    }

    fun onIntent(intent: ManagerIntent) {
        when (intent) {
            is ManagerIntent.LoadStats -> {
                currentFacilityId = intent.facilityId
                currentPeriod = intent.period
                loadStats()
            }
            is ManagerIntent.ChangePeriod -> {
                currentPeriod = intent.period
                loadStats()
            }
            ManagerIntent.Refresh -> loadStats()
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            _state.value = ManagerState.Loading
            repository.getFacilityStats(currentFacilityId, currentPeriod)
                .onSuccess { stats ->
                    _state.value = ManagerState.Success(stats, currentPeriod)
                }
                .onFailure { error ->
                    _state.value = ManagerState.Error(error.message ?: "Failed to load statistics")
                }
        }
    }
}
