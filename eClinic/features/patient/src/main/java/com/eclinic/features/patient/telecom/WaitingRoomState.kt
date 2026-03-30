package com.eclinic.features.patient.telecom

import com.eclinic.core.common.model.TeleconsultationSession

sealed interface WaitingRoomState {
    object Initial : WaitingRoomState
    object Loading : WaitingRoomState
    data class Waiting(val session: TeleconsultationSession, val queuePosition: Int) : WaitingRoomState
    object IncomingCall : WaitingRoomState
    object InCall : WaitingRoomState
    data class Error(val message: String) : WaitingRoomState
}

sealed interface WaitingRoomIntent {
    data class JoinWaitingRoom(val patientId: String) : WaitingRoomIntent
    object AcceptCall : WaitingRoomIntent
    object DeclineCall : WaitingRoomIntent
    object EndCall : WaitingRoomIntent
}
