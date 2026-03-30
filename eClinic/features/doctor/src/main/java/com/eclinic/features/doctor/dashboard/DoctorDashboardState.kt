package com.eclinic.features.doctor.dashboard

import com.eclinic.core.common.model.Appointment
import com.eclinic.core.common.model.ClinicalAlert
import com.eclinic.core.common.model.PatientQueueItem
import com.eclinic.core.common.model.Task

sealed interface DoctorDashboardState {
    object Loading : DoctorDashboardState
    data class Success(
        val queue: List<PatientQueueItem>,
        val appointments: List<Appointment>,
        val pendingTasks: List<Task>,
        val alerts: List<ClinicalAlert>
    ) : DoctorDashboardState
    data class Error(val message: String) : DoctorDashboardState
}

sealed interface DoctorDashboardIntent {
    object Refresh : DoctorDashboardIntent
    data class SelectPatient(val patientId: String) : DoctorDashboardIntent
    data class DismissAlert(val alertId: String) : DoctorDashboardIntent
}
