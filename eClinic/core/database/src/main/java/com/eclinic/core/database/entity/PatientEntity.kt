package com.eclinic.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "patients")
data class PatientEntity(
    @PrimaryKey val patientId: String,
    val nationalId: String,
    val firstName: String,
    val lastName: String,
    val dateOfBirth: Long, // epoch ms
    val gender: String,
    val facilityId: String,
    val lastSyncedAt: Long,
    val isSyncPending: Boolean = false
)
