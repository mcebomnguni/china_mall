package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class ProvincePerformance(
    val provinceId: String,
    val provinceName: String,
    val totalPatients: Int,
    val healthReadinessIndex: Float, // 0.0 to 1.0
    val status: HealthStatus
)

@Serializable
data class NationalStats(
    val period: StatsPeriod,
    val totalPatientsNationwide: Int,
    val nationalBedOccupancyRate: Float,
    val nationalImmunizationCoverage: Float,
    val provincePerformances: List<ProvincePerformance>,
    val nationalDiseaseBurden: List<DiagnosisFrequency>,
    val healthcareWorkforceNationwide: Int
)
