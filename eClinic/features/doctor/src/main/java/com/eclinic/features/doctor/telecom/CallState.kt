package com.eclinic.features.doctor.telecom

import com.eclinic.core.common.model.TeleconsultationSession

sealed interface CallState {
    object Initial : CallState
    object Loading : CallState
    data class Ready(val session: TeleconsultationSession) : CallState
    object Calling : CallState
    object Connected : CallState
    data class Error(val message: String) : CallState
}

sealed interface CallIntent {
    data class InitCall(val patientId: String) : CallIntent
    object StartCall : CallIntent
    object EndCall : CallIntent
    object ToggleMute : CallIntent
    object ToggleCamera : CallIntent
}
