package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
enum class Priority {
    EMERGENCY, URGENT, ROUTINE
}

@Serializable
data class PatientQueueItem(
    val id: String,
    val patientId: String,
    val patientName: String,
    val priority: Priority,
    val waitingTimeMinutes: Int,
    val reasonForVisit: String
)

@Serializable
data class Appointment(
    val id: String,
    val patientName: String,
    val time: String,
    val type: String
)

@Serializable
data class Task(
    val id: String,
    val title: String,
    val deadline: String,
    val isCompleted: Boolean = false
)

@Serializable
data class ClinicalAlert(
    val id: String,
    val patientName: String,
    val message: String,
    val severity: String // e.g., "CRITICAL", "WARNING"
)
