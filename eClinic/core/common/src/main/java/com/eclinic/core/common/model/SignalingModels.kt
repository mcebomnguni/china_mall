package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class SignalingMessage(
    val type: SignalingType,
    val senderId: String,
    val receiverId: String,
    val sdp: String? = null,
    val iceCandidate: IceCandidateModel? = null
)

@Serializable
enum class SignalingType {
    OFFER, ANSWER, ICE_CANDIDATE
}

@Serializable
data class IceCandidateModel(
    val sdpMid: String,
    val sdpMLineIndex: Int,
    val sdp: String
)
