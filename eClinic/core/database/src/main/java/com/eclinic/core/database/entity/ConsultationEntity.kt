package com.eclinic.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "consultations")
data class ConsultationEntity(
    @PrimaryKey val consultationId: String,
    val patientId: String,
    val doctorId: String,
    val facilityId: String,
    val startedAt: Long,
    val completedAt: Long?,
    val soapNote: String, // JSON serialized
    val icdCodes: String, // JSON array
    val syncStatus: String // SYNCED, PENDING_UPLOAD, etc.
)
