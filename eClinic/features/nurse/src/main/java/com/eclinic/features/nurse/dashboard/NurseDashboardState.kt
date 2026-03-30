package com.eclinic.features.nurse.dashboard

import com.eclinic.core.common.model.PatientQueueItem

sealed interface NurseDashboardState {
    object Loading : NurseDashboardState
    data class Success(
        val wardOverview: List<PatientQueueItem>,
        val pendingVitals: List<String>,
        val pendingMedications: List<String>
    ) : NurseDashboardState
    data class Error(val message: String) : NurseDashboardState
}

sealed interface NurseDashboardIntent {
    object Refresh : NurseDashboardIntent
    data class TriagePatient(val patientId: String) : NurseDashboardIntent
    data class RecordVitals(val patientId: String) : NurseDashboardIntent
    data class AdministerMedication(val patientId: String) : NurseDashboardIntent
}
