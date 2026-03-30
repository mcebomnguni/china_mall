package com.eclinic.features.nurse.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.features.nurse.domain.repository.NurseRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NurseDashboardViewModel @Inject constructor(
    private val repository: NurseRepository
) : ViewModel() {

    private val _state = MutableStateFlow<NurseDashboardState>(NurseDashboardState.Loading)
    val state: StateFlow<NurseDashboardState> = _state.asStateFlow()

    init {
        loadDashboard()
    }

    fun onIntent(intent: NurseDashboardIntent) {
        when (intent) {
            NurseDashboardIntent.Refresh -> loadDashboard()
            is NurseDashboardIntent.TriagePatient -> {
                // Navigate to Triage Screen
            }
            is NurseDashboardIntent.RecordVitals -> {
                // Navigate to Vitals Screen
            }
            is NurseDashboardIntent.AdministerMedication -> {
                // Navigate to Medication Screen
            }
        }
    }

    private fun loadDashboard() {
        viewModelScope.launch {
            _state.value = NurseDashboardState.Loading
            // In a real app, this would come from a SessionManager
            val nurseId = "nurse-456"
            repository.getNurseDashboard(nurseId)
                .onSuccess {
                    _state.value = NurseDashboardState.Success(
                        wardOverview = it.wardOverview,
                        pendingVitals = it.pendingVitals,
                        pendingMedications = it.pendingMedications
                    )
                }
                .onFailure { error ->
                    _state.value = NurseDashboardState.Error(error.message ?: "Failed to load dashboard")
                }
        }
    }
}
