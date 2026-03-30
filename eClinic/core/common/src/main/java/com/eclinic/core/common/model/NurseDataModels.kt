package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
enum class TriageCategory {
    RED,    // Emergency
    ORANGE, // Very Urgent
    YELLOW, // Urgent
    GREEN   // Standard
}

@Serializable
data class TriageAssessment(
    val patientId: String,
    val category: TriageCategory,
    val chiefComplaint: String
)

@Serializable
data class Vitals(
    val vitalsId: String,
    val patientId: String,
    val recordedBy: String, // Nurse ID
    val systolicBP: Int?,
    val diastolicBP: Int?,
    val heartRate: Int?,
    val temperature: Float?,
    val spo2: Int?,
    val weight: Float?,
    val height: Float?,
    val bloodGlucose: Float?,
    val recordedAt: Long // Epoch ms
)

@Serializable
data class NurseDashboardData(
    val wardOverview: List<PatientQueueItem>,
    val pendingVitals: List<String>, // List of Patient Names
    val pendingMedications: List<String> // List of Patient Names
)
