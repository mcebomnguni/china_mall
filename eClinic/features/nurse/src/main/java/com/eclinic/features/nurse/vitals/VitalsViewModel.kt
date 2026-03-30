package com.eclinic.features.nurse.vitals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.Vitals
import com.eclinic.features.nurse.domain.repository.NurseRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class VitalsViewModel @Inject constructor(
    private val repository: NurseRepository
) : ViewModel() {

    private val _state = MutableStateFlow<VitalsState>(VitalsState.Initial)
    val state: StateFlow<VitalsState> = _state.asStateFlow()

    fun onIntent(intent: VitalsIntent) {
        when (intent) {
            is VitalsIntent.SaveVitals -> saveVitals(intent)
        }
    }

    private fun saveVitals(intent: VitalsIntent.SaveVitals) {
        viewModelScope.launch {
            _state.value = VitalsState.Loading
            
            val vitals = Vitals(
                vitalsId = java.util.UUID.randomUUID().toString(),
                patientId = intent.patientId,
                recordedBy = "nurse-456", // In real app, from SessionManager
                systolicBP = intent.systolicBP.toIntOrNull(),
                diastolicBP = intent.diastolicBP.toIntOrNull(),
                heartRate = intent.heartRate.toIntOrNull(),
                temperature = intent.temperature.toFloatOrNull(),
                spo2 = intent.spo2.toIntOrNull(),
                weight = intent.weight.toFloatOrNull(),
                height = intent.height.toFloatOrNull(),
                bloodGlucose = intent.bloodGlucose.toFloatOrNull(),
                recordedAt = System.currentTimeMillis()
            )

            repository.recordVitals(vitals)
                .onSuccess {
                    _state.value = VitalsState.Success
                }
                .onFailure { error ->
                    _state.value = VitalsState.Error(error.message ?: "Failed to save vitals")
                }
        }
    }
}
