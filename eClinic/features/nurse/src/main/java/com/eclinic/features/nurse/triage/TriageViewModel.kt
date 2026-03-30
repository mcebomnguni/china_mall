package com.eclinic.features.nurse.triage

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.*
import com.eclinic.features.nurse.domain.repository.NurseRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TriageViewModel @Inject constructor(
    private val repository: NurseRepository
) : ViewModel() {

    private val _state = MutableStateFlow(TriageState())
    val state: StateFlow<TriageState> = _state.asStateFlow()

    fun onIntent(intent: TriageIntent) {
        when (intent) {
            is TriageIntent.LoadPatient -> _state.update { it.copy(patientId = intent.patientId) }
            is TriageIntent.UpdateMobility -> _state.update { it.copy(mobility = intent.mobility) }
            is TriageIntent.UpdateTrauma -> _state.update { it.copy(hasTrauma = intent.hasTrauma) }
            is TriageIntent.UpdateTews -> _state.update { it.copy(tewsScore = intent.score) }
            is TriageIntent.ToggleDiscriminator -> toggleDiscriminator(intent.discriminator)
            TriageIntent.CalculateResult -> calculateSats()
            TriageIntent.SaveTriage -> saveTriage()
        }
    }

    private fun toggleDiscriminator(discriminator: Discriminator) {
        _state.update { currentState ->
            val currentSet = currentState.selectedDiscriminators
            val newSet = if (currentSet.contains(discriminator)) {
                currentSet - discriminator
            } else {
                currentSet + discriminator
            }
            currentState.copy(selectedDiscriminators = newSet)
        }
    }

    private fun calculateSats() {
        val currentState = _state.value
        
        // SATS Logic Implementation (Simplified for MVP)
        // Rule 1: High-priority discriminators override everything to RED
        val hasRedDiscriminator = currentState.selectedDiscriminators.any { 
            it == Discriminator.AIRWAY_OBSTRUCTION || 
            it == Discriminator.SHOCK || 
            it == Discriminator.SEVERE_RESPIRATORY_DISTRESS 
        }

        // Rule 2: TEWS Score mapping
        val category = when {
            hasRedDiscriminator -> TriageCategory.RED
            currentState.tewsScore >= 7 -> TriageCategory.RED
            currentState.tewsScore >= 5 -> TriageCategory.ORANGE
            currentState.tewsScore >= 3 -> TriageCategory.YELLOW
            else -> TriageCategory.GREEN
        }

        val action = when (category) {
            TriageCategory.RED -> "Immediate medical attention required."
            TriageCategory.ORANGE -> "Very urgent. Review within 10 minutes."
            TriageCategory.YELLOW -> "Urgent. Review within 60 minutes."
            TriageCategory.GREEN -> "Standard. Review within 4 hours."
        }

        _state.update { it.copy(result = SatsResult(currentState.tewsScore, category, action)) }
    }

    private fun saveTriage() {
        viewModelScope.launch {
            val currentState = _state.value
            val result = currentState.result ?: return@launch
            
            _state.update { it.copy(isLoading = true) }
            
            val assessment = TriageAssessment(
                patientId = currentState.patientId,
                category = result.triageCategory,
                chiefComplaint = "SATS Assessment: TEWS ${result.finalScore}"
            )

            repository.recordTriage(assessment)
                .onSuccess {
                    _state.update { it.copy(isLoading = false, isSaved = true) }
                }
                .onFailure { error ->
                    _state.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }
}
