package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class LoginResponse(
    val user: User,
    val token: AuthToken
)
