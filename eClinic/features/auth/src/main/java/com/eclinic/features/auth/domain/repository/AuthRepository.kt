package com.eclinic.features.auth.domain.repository

import com.eclinic.core.common.model.LoginResponse

interface AuthRepository {
    suspend fun login(email: String, password: String): Result<LoginResponse>
    suspend fun logout()
    suspend fun getSavedUserToken(): String?
}
