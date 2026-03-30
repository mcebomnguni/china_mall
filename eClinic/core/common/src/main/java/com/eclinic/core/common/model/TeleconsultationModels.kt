package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class TeleconsultationSession(
    val sessionId: String,
    val patientId: String,
    val doctorId: String,
    val scheduledTime: Long,
    val status: SessionStatus = SessionStatus.SCHEDULED,
    val roomUrl: String? = null // WebRTC room identifier
)

@Serializable
enum class SessionStatus {
    SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED, PATIENT_WAITING, DOCTOR_READY
}

@Serializable
data class IceServerConfig(
    val urls: List<String>,
    val username: String? = null,
    val credential: String? = null
)
