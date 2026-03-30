package com.eclinic.features.nurse.vitals

sealed interface VitalsState {
    object Initial : VitalsState
    object Loading : VitalsState
    object Success : VitalsState
    data class Error(val message: String) : VitalsState
}

sealed interface VitalsIntent {
    data class SaveVitals(
        val patientId: String,
        val systolicBP: String,
        val diastolicBP: String,
        val heartRate: String,
        val temperature: String,
        val spo2: String,
        val weight: String,
        val height: String,
        val bloodGlucose: String
    ) : VitalsIntent
}
