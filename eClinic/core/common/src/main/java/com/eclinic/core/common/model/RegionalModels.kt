package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class DistrictPerformance(
    val districtId: String,
    val districtName: String,
    val totalPatients: Int,
    val healthIndex: Float, // 0.0 to 1.0
    val status: HealthStatus
)

@Serializable
data class RegionalStats(
    val regionId: String,
    val regionName: String,
    val period: StatsPeriod,
    val totalPatients: Int,
    val totalBedOccupancy: Float,
    val districtPerformances: List<DistrictPerformance>,
    val regionalDiseaseProfile: List<DiagnosisFrequency>,
    val vacancyRate: Float
)
