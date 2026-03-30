package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class FacilityPerformance(
    val facilityId: String,
    val facilityName: String,
    val patientLoad: Int,
    val averageWaitTime: Int,
    val staffUtilization: Float,
    val status: HealthStatus
)

@Serializable
enum class HealthStatus {
    NORMAL, UNDER_PRESSURE, CRITICAL
}

@Serializable
data class DistrictStats(
    val districtId: String,
    val districtName: String,
    val period: StatsPeriod,
    val totalPatients: Int,
    val aggregateBedOccupancy: Float?,
    val facilityPerformances: List<FacilityPerformance>,
    val diseaseSurveillance: List<DiagnosisFrequency>,
    val stockoutRates: Float
)
