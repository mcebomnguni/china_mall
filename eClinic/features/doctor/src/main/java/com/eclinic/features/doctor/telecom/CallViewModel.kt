package com.eclinic.features.doctor.telecom

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.SignalingMessage
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
class CallViewModel @Inject constructor(
    private val signalingClient: SignalingClient,
    private val webRtcManager: WebRtcManager
) : ViewModel() {

    private val _state = MutableStateFlow<CallState>(CallState.Initial)
    val state: StateFlow<CallState> = _state.asStateFlow()

    private var currentSession: TeleconsultationSession? = null
    private var doctorId: String = "doc-123" // From session

    fun onIntent(intent: CallIntent) {
        when (intent) {
            is CallIntent.InitCall -> initCall(intent.patientId)
            CallIntent.StartCall -> startCall()
            CallIntent.EndCall -> endCall()
            CallIntent.ToggleMute -> {}
            CallIntent.ToggleCamera -> {}
        }
    }

    private fun initCall(patientId: String) {
        viewModelScope.launch {
            _state.value = CallState.Loading
            signalingClient.connect(doctorId)
            
            // Mock session creation
            currentSession = TeleconsultationSession(
                sessionId = "sess-${java.util.UUID.randomUUID()}",
                patientId = patientId,
                doctorId = doctorId,
                scheduledTime = System.currentTimeMillis()
            )
            _state.value = CallState.Ready(currentSession!!)
        }
    }

    private fun startCall() {
        val session = currentSession ?: return
        viewModelScope.launch {
            _state.value = CallState.Calling
            
            // Send WebRTC Offer via signaling
            val offer = SignalingMessage(
                type = SignalingType.OFFER,
                senderId = doctorId,
                receiverId = session.patientId,
                sdp = "v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n..." // Placeholder SDP
            )
            signalingClient.sendMessage(offer)
            
            // In a real app, we wait for the ANSWER here
            // For MVP simulation, we move to Connected
            _state.value = CallState.Connected
        }
    }

    private fun endCall() {
        _state.value = CallState.Initial
        signalingClient.disconnect()
        webRtcManager.dispose()
    }

    override fun onCleared() {
        super.onCleared()
        signalingClient.disconnect()
    }
}
