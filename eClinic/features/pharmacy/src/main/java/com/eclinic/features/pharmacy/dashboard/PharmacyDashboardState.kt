package com.eclinic.features.pharmacy.dashboard

import com.eclinic.core.common.model.PrescriptionToDispense

sealed interface PharmacyDashboardState {
    object Loading : PharmacyDashboardState
    data class Success(
        val pendingPrescriptions: List<PrescriptionToDispense>,
        val recentDispenseHistory: List<PrescriptionToDispense> = emptyList()
    ) : PharmacyDashboardState
    data class Error(val message: String) : PharmacyDashboardState
}

sealed interface PharmacyDashboardIntent {
    object Refresh : PharmacyDashboardIntent
    data class DispenseMedication(val prescriptionId: String, val items: Map<String, Int>) : PharmacyDashboardIntent
    data class CancelPrescription(val prescriptionId: String) : PharmacyDashboardIntent
}
