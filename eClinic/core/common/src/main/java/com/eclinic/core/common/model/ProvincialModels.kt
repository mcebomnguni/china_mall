package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class RegionPerformance(
    val regionId: String,
    val regionName: String,
    val totalPatients: Int,
    val kpiComplianceRate: Float, // 0.0 to 1.0
    val status: HealthStatus
)

@Serializable
data class ProvincialStats(
    val provinceId: String,
    val provinceName: String,
    val period: StatsPeriod,
    val totalPatients: Int,
    val provincialMortalityRate: Float,
    val regionPerformances: List<RegionPerformance>,
    val provincialDiseaseBurden: List<DiagnosisFrequency>,
    val healthcareWorkforceCount: Int
)
