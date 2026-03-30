package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class AppointmentSlot(
    val startTime: Long,
    val endTime: Long,
    val isAvailable: Boolean
)

@Serializable
data class AvailableAppointments(
    val facilityId: String,
    val date: Long,
    val slots: List<AppointmentSlot>
)

@Serializable
data class BookAppointmentRequest(
    val patientId: String,
    val facilityId: String,
    val slotStartTime: Long
)

@Serializable
data class BookAppointmentResponse(
    val success: Boolean,
    val appointmentDetails: Appointment
)
