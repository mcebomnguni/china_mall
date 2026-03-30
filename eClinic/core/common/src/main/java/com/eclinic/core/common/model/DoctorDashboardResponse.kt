package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class DoctorDashboardResponse(
    val queue: List<PatientQueueItem>,
    val appointments: List<Appointment>,
    val pendingTasks: List<Task>,
    val alerts: List<ClinicalAlert>
)
