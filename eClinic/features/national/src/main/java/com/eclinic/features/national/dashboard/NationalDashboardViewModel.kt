package com.eclinic.features.national.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.StatsPeriod
import com.eclinic.features.national.domain.repository.NationalRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NationalDashboardViewModel @Inject constructor(
    private val repository: NationalRepository
) : ViewModel() {

    private val _state = MutableStateFlow<NationalDashboardState>(NationalDashboardState.Loading)
    val state: StateFlow<NationalDashboardState> = _state.asStateFlow()

    private var currentPeriod: StatsPeriod = StatsPeriod.ANNUALLY

    init {
        loadStats()
    }

    fun onIntent(intent: NationalDashboardIntent) {
        when (intent) {
            is NationalDashboardIntent.LoadStats -> {
                currentPeriod = intent.period
                loadStats()
            }
            is NationalDashboardIntent.ChangePeriod -> {
                currentPeriod = intent.period
                loadStats()
            }
            NationalDashboardIntent.Refresh -> loadStats()
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            _state.value = NationalDashboardState.Loading
            repository.getNationalStats(currentPeriod)
                .onSuccess { stats ->
                    _state.value = NationalDashboardState.Success(stats, currentPeriod)
                }
                .onFailure { error ->
                    _state.value = NationalDashboardState.Error(error.message ?: "Failed to load national statistics")
                }
        }
    }
}
