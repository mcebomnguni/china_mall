package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class PatientDashboardData(
    val nextAppointment: Appointment?,
    val activeMedications: List<String>,
    val recentVisitSummary: VisitSummary?,
    val healthReminders: List<String>
)

@Serializable
data class VisitSummary(
    val date: Long,
    val facilityName: String,
    val diagnosis: String,
    val plan: String
)

@Serializable
data class MedicalRecord(
    val id: String,
    val type: RecordType,
    val date: Long,
    val title: String,
    val content: String,
    val doctorName: String
)

@Serializable
enum class RecordType {
    CONSULTATION, LAB_RESULT, PRESCRIPTION, REFERRAL
}
