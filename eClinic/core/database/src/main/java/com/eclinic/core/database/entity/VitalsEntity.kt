package com.eclinic.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "vitals")
data class VitalsEntity(
    @PrimaryKey val vitalsId: String,
    val patientId: String,
    val recordedBy: String,
    val facilityId: String,
    val systolicBP: Int?,
    val diastolicBP: Int?,
    val heartRate: Int?,
    val temperature: Float?,
    val spo2: Int?,
    val weight: Float?,
    val height: Float?,
    val bloodGlucose: Float?,
    val recordedAt: Long,
    val syncStatus: String // SYNCED, PENDING_UPLOAD
)
