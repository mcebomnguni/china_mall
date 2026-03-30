package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
enum class StatsPeriod {
    DAILY, WEEKLY, MONTHLY, ANNUALLY
}

@Serializable
data class DiagnosisFrequency(
    val icd10Code: String,
    val description: String,
    val count: Int
)

@Serializable
data class FacilityStats(
    val facilityId: String,
    val period: StatsPeriod,
    val totalPatients: Int,
    val averageWaitTimeMinutes: Int,
    val bedOccupancyRate: Float? = null,
    val topDiagnoses: List<DiagnosisFrequency>,
    val staffUtilisationRate: Float,
    val stockoutCount: Int,
    val dnaRate: Float // Did Not Attend (Missed Appointments) rate
)
