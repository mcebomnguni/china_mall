package com.eclinic.features.patient.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.features.patient.domain.repository.PatientRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PatientDashboardViewModel @Inject constructor(
    private val repository: PatientRepository
) : ViewModel() {

    private val _state = MutableStateFlow<PatientDashboardState>(PatientDashboardState.Loading)
    val state: StateFlow<PatientDashboardState> = _state.asStateFlow()

    private val patientId = "pat-789" // Default for MVP

    init {
        loadDashboardData()
    }

    fun onIntent(intent: PatientDashboardIntent) {
        when (intent) {
            PatientDashboardIntent.Refresh -> loadDashboardData()
            PatientDashboardIntent.LoadMedicalRecords -> loadRecords()
            is PatientDashboardIntent.BookAppointment -> {
                // Handle appointment booking
            }
        }
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            _state.value = PatientDashboardState.Loading
            repository.getDashboardData(patientId)
                .onSuccess { data ->
                    _state.value = PatientDashboardState.Success(data)
                }
                .onFailure { error ->
                    _state.value = PatientDashboardState.Error(error.message ?: "Failed to load dashboard")
                }
        }
    }

    private fun loadRecords() {
        viewModelScope.launch {
            val currentState = _state.value
            if (currentState is PatientDashboardState.Success) {
                repository.getMedicalRecords(patientId)
                    .onSuccess { records ->
                        _state.value = currentState.copy(records = records)
                    }
            }
        }
    }
}
