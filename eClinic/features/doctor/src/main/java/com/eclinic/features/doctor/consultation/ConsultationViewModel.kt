package com.eclinic.features.doctor.consultation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.Diagnosis
import com.eclinic.core.common.model.SoapNote
import com.eclinic.features.doctor.domain.repository.DoctorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ConsultationViewModel @Inject constructor(
    private val repository: DoctorRepository
) : ViewModel() {

    private val _state = MutableStateFlow<ConsultationState>(ConsultationState.Initial)
    val state: StateFlow<ConsultationState> = _state.asStateFlow()

    fun onIntent(intent: ConsultationIntent) {
        when (intent) {
            is ConsultationIntent.StartConsultation -> startConsultation(intent.patientId)
            is ConsultationIntent.UpdateSoapNote -> updateSoapNote(intent.soapNote)
            is ConsultationIntent.AddDiagnosis -> addDiagnosis(intent.diagnosis)
            is ConsultationIntent.RemoveDiagnosis -> removeDiagnosis(intent.icd10Code)
            ConsultationIntent.SaveConsultation -> saveConsultation()
        }
    }

    private fun startConsultation(patientId: String) {
        viewModelScope.launch {
            _state.value = ConsultationState.Loading
            repository.startConsultation(patientId)
                .onSuccess { consultation ->
                    _state.value = ConsultationState.Active(consultation)
                }
                .onFailure { error ->
                    _state.value = ConsultationState.Error(error.message ?: "Failed to start consultation")
                }
        }
    }

    private fun updateSoapNote(soapNote: SoapNote) {
        _state.update { currentState ->
            if (currentState is ConsultationState.Active) {
                currentState.copy(consultation = currentState.consultation.copy(soapNote = soapNote))
            } else currentState
        }
    }

    private fun addDiagnosis(diagnosis: Diagnosis) {
        _state.update { currentState ->
            if (currentState is ConsultationState.Active) {
                val updatedDiagnoses = currentState.consultation.diagnoses + diagnosis
                currentState.copy(consultation = currentState.consultation.copy(diagnoses = updatedDiagnoses))
            } else currentState
        }
    }

    private fun removeDiagnosis(icd10Code: String) {
        _state.update { currentState ->
            if (currentState is ConsultationState.Active) {
                val updatedDiagnoses = currentState.consultation.diagnoses.filterNot { it.icd10Code == icd10Code }
                currentState.copy(consultation = currentState.consultation.copy(diagnoses = updatedDiagnoses))
            } else currentState
        }
    }

    private fun saveConsultation() {
        viewModelScope.launch {
            val currentState = _state.value
            if (currentState is ConsultationState.Active) {
                _state.value = ConsultationState.Loading
                repository.saveConsultation(currentState.consultation)
                    .onSuccess {
                        _state.value = ConsultationState.Saved
                    }
                    .onFailure { error ->
                        _state.value = ConsultationState.Error(error.message ?: "Failed to save consultation")
                    }
            }
        }
    }
}
