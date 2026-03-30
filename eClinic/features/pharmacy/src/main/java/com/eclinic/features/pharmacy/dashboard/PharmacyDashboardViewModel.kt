package com.eclinic.features.pharmacy.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.DispenseRecord
import com.eclinic.features.pharmacy.domain.repository.PharmacyRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PharmacyDashboardViewModel @Inject constructor(
    private val repository: PharmacyRepository
) : ViewModel() {

    private val _state = MutableStateFlow<PharmacyDashboardState>(PharmacyDashboardState.Loading)
    val state: StateFlow<PharmacyDashboardState> = _state.asStateFlow()

    private val facilityId = "fac-123" // Default for MVP

    init {
        loadPrescriptions()
    }

    fun onIntent(intent: PharmacyDashboardIntent) {
        when (intent) {
            PharmacyDashboardIntent.Refresh -> loadPrescriptions()
            is PharmacyDashboardIntent.DispenseMedication -> dispense(intent.prescriptionId, intent.items)
            is PharmacyDashboardIntent.CancelPrescription -> {
                // Implementation for cancelling
            }
        }
    }

    private fun loadPrescriptions() {
        viewModelScope.launch {
            _state.value = PharmacyDashboardState.Loading
            repository.getPendingPrescriptions(facilityId)
                .onSuccess { prescriptions ->
                    _state.value = PharmacyDashboardState.Success(prescriptions)
                }
                .onFailure { error ->
                    _state.value = PharmacyDashboardState.Error(error.message ?: "Failed to load prescriptions")
                }
        }
    }

    private fun dispense(prescriptionId: String, items: Map<String, Int>) {
        viewModelScope.launch {
            val record = DispenseRecord(
                dispenseId = java.util.UUID.randomUUID().toString(),
                prescriptionId = prescriptionId,
                pharmacistId = "pharm-456", // From session
                itemsDispensed = items,
                dateDispensed = System.currentTimeMillis()
            )
            
            repository.recordDispense(record)
                .onSuccess {
                    loadPrescriptions() // Refresh list
                }
        }
    }
}
