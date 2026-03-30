package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class AuthToken(
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: Long
)
