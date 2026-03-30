package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class PrescriptionToDispense(
    val prescriptionId: String,
    val patientName: String,
    val doctorName: String,
    val dateIssued: Long,
    val items: List<PrescriptionItem>,
    val status: DispensingStatus = DispensingStatus.PENDING
)

@Serializable
enum class DispensingStatus {
    PENDING, PARTIALLY_DISPENSED, DISPENSED, CANCELLED
}

@Serializable
data class DispenseRecord(
    val dispenseId: String,
    val prescriptionId: String,
    val pharmacistId: String,
    val itemsDispensed: Map<String, Int>, // Nappi code to quantity
    val dateDispensed: Long
)
