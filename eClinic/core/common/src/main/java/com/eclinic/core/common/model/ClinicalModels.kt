package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class SoapNote(
    val subjective: String = "",
    val objective: String = "",
    val assessment: String = "",
    val plan: String = ""
)

@Serializable
data class Diagnosis(
    val icd10Code: String,
    val description: String,
    val isPrimary: Boolean = true
)

@Serializable
data class Consultation(
    val consultationId: String,
    val patientId: String,
    val doctorId: String,
    val facilityId: String,
    val startedAt: Long,
    val completedAt: Long? = null,
    val soapNote: SoapNote,
    val diagnoses: List<Diagnosis> = emptyList()
)
