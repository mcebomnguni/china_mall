package com.eclinic.core.telecom

import com.eclinic.core.common.model.SignalingMessage
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SignalingClientImpl @Inject constructor() : SignalingClient {

    private val _messageFlow = MutableSharedFlow<SignalingMessage>(extraBufferCapacity = 10)
    
    override fun getMessages(): Flow<SignalingMessage> = _messageFlow.asSharedFlow()

    override suspend fun sendMessage(message: SignalingMessage) {
        // In a real app, this would send to a WebSocket or Firebase
        // For MVP, we simulate by emitting back if it's meant for "us" (loopback for testing)
        // or just log it.
        println("Signaling: Sending message of type ${message.type} to ${message.receiverId}")
    }

    override fun connect(userId: String) {
        println("Signaling: Connected as $userId")
    }

    override fun disconnect() {
        println("Signaling: Disconnected")
    }
    
    // Helper for simulation
    suspend fun simulateReceivedMessage(message: SignalingMessage) {
        _messageFlow.emit(message)
    }
}
