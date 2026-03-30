package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class Medication(
    val nappiCode: String,
    val name: String,
    val genericName: String,
    val strength: String,
    val form: String // e.g., Tablet, Syrup, Injection
)

@Serializable
data class PrescriptionItem(
    val medication: Medication,
    val dosage: String,
    val frequency: String,
    val route: String,
    val duration: String,
    val instructions: String? = null
)

@Serializable
data class Prescription(
    val prescriptionId: String,
    val patientId: String,
    val doctorId: String,
    val facilityId: String,
    val dateIssued: Long,
    val items: List<PrescriptionItem>,
    val isElectronicSignaturePresent: Boolean = false
)
