package com.eclinic.features.doctor.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.features.doctor.domain.repository.DoctorDashboardRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DoctorDashboardViewModel @Inject constructor(
    private val repository: DoctorDashboardRepository
) : ViewModel() {

    private val _state = MutableStateFlow<DoctorDashboardState>(DoctorDashboardState.Loading)
    val state: StateFlow<DoctorDashboardState> = _state.asStateFlow()

    init {
        loadDashboardData()
    }

    fun onIntent(intent: DoctorDashboardIntent) {
        when (intent) {
            is DoctorDashboardIntent.Refresh -> loadDashboardData()
            is DoctorDashboardIntent.SelectPatient -> {
                // Handle patient selection (navigation to patient records)
            }
            is DoctorDashboardIntent.DismissAlert -> dismissAlert(intent.alertId)
        }
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            _state.value = DoctorDashboardState.Loading
            // In a real app, these would come from a SessionManager or UserPreferences
            val doctorId = "doc-123"
            val facilityId = "fac-456"

            repository.getDashboardData(doctorId, facilityId)
                .onSuccess { data ->
                    _state.value = DoctorDashboardState.Success(
                        queue = data.queue,
                        appointments = data.appointments,
                        pendingTasks = data.pendingTasks,
                        alerts = data.alerts
                    )
                }
                .onFailure { error ->
                    _state.value = DoctorDashboardState.Error(error.message ?: "Failed to load dashboard")
                }
        }
    }

    private fun dismissAlert(alertId: String) {
        val currentState = _state.value
        if (currentState is DoctorDashboardState.Success) {
            _state.value = currentState.copy(
                alerts = currentState.alerts.filterNot { it.id == alertId }
            )
        }
    }
}
