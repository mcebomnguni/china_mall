package com.eclinic.core.telecom

import com.eclinic.core.common.model.SignalingMessage
import kotlinx.coroutines.flow.Flow

interface SignalingClient {
    fun getMessages(): Flow<SignalingMessage>
    suspend fun sendMessage(message: SignalingMessage)
    fun connect(userId: String)
    fun disconnect()
}
