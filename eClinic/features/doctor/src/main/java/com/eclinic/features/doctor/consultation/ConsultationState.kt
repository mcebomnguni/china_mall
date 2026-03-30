package com.eclinic.features.doctor.consultation

import com.eclinic.core.common.model.Consultation
import com.eclinic.core.common.model.Diagnosis
import com.eclinic.core.common.model.SoapNote

sealed interface ConsultationState {
    object Initial : ConsultationState
    object Loading : ConsultationState
    data class Active(
        val consultation: Consultation,
        val availableDiagnoses: List<Diagnosis> = emptyList()
    ) : ConsultationState
    data class Error(val message: String) : ConsultationState
    object Saved : ConsultationState
}

sealed interface ConsultationIntent {
    data class StartConsultation(val patientId: String) : ConsultationIntent
    data class UpdateSoapNote(val soapNote: SoapNote) : ConsultationIntent
    data class AddDiagnosis(val diagnosis: Diagnosis) : ConsultationIntent
    data class RemoveDiagnosis(val icd10Code: String) : ConsultationIntent
    object SaveConsultation : ConsultationIntent
}
