package com.eclinic.features.patient.dashboard

import com.eclinic.core.common.model.MedicalRecord
import com.eclinic.core.common.model.PatientDashboardData

sealed interface PatientDashboardState {
    object Loading : PatientDashboardState
    data class Success(
        val dashboardData: PatientDashboardData,
        val records: List<MedicalRecord> = emptyList()
    ) : PatientDashboardState
    data class Error(val message: String) : PatientDashboardState
}

sealed interface PatientDashboardIntent {
    object Refresh : PatientDashboardIntent
    object LoadMedicalRecords : PatientDashboardIntent
    data class BookAppointment(val facilityId: String) : PatientDashboardIntent
}
