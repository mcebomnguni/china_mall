package com.eclinic.features.patient.telecom

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.SignalingType
import com.eclinic.core.common.model.TeleconsultationSession
import com.eclinic.core.telecom.SignalingClient
import com.eclinic.core.telecom.WebRtcManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class WaitingRoomViewModel @Inject constructor(
    private val signalingClient: SignalingClient,
    private val webRtcManager: WebRtcManager
) : ViewModel() {

    private val _state = MutableStateFlow<WaitingRoomState>(WaitingRoomState.Initial)
    val state: StateFlow<WaitingRoomState> = _state.asStateFlow()

    private var currentPatientId: String? = null

    init {
        listenForMessages()
    }

    fun onIntent(intent: WaitingRoomIntent) {
        when (intent) {
            is WaitingRoomIntent.JoinWaitingRoom -> joinWaitingRoom(intent.patientId)
            WaitingRoomIntent.AcceptCall -> acceptCall()
            WaitingRoomIntent.DeclineCall -> declineCall()
            WaitingRoomIntent.EndCall -> endCall()
        }
    }

    private fun joinWaitingRoom(patientId: String) {
        currentPatientId = patientId
        viewModelScope.launch {
            _state.value = WaitingRoomState.Loading
            signalingClient.connect(patientId)
            
            // Mock joining session
            val session = TeleconsultationSession(
                sessionId = "sess-999",
                patientId = patientId,
                doctorId = "doc-123",
                scheduledTime = System.currentTimeMillis()
            )
            _state.value = WaitingRoomState.Waiting(session, queuePosition = 2)
        }
    }

    private fun listenForMessages() {
        viewModelScope.launch {
            signalingClient.getMessages().collect { message ->
                if (message.type == SignalingType.OFFER) {
                    _state.value = WaitingRoomState.IncomingCall
                }
            }
        }
    }

    private fun acceptCall() {
        _state.value = WaitingRoomState.InCall
        // PeerConnection logic will be added here
    }

    private fun declineCall() {
        _state.value = WaitingRoomState.Initial
        signalingClient.disconnect()
    }

    private fun endCall() {
        _state.value = WaitingRoomState.Initial
        signalingClient.disconnect()
        webRtcManager.dispose()
    }

    override fun onCleared() {
        super.onCleared()
        signalingClient.disconnect()
    }
}
