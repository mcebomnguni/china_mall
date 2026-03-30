package com.eclinic.features.auth.data.repository

import com.eclinic.core.common.model.LoginResponse
import com.eclinic.core.network.AuthService
import com.eclinic.core.security.TokenManager
import com.eclinic.features.auth.domain.repository.AuthRepository
import javax.inject.Inject

class AuthRepositoryImpl @Inject constructor(
    private val authService: AuthService,
    private val tokenManager: TokenManager
) : AuthRepository {

    override suspend fun login(email: String, password: String): Result<LoginResponse> {
        return try {
            val response = authService.login(mapOf("email" to email, "password" to password))
            tokenManager.saveTokens(
                accessToken = response.token.accessToken,
                refreshToken = response.token.refreshToken
            )
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun logout() {
        try {
            authService.logout()
        } finally {
            tokenManager.clearTokens()
        }
    }

    override suspend fun getSavedUserToken(): String? {
        return tokenManager.getAccessToken()
    }
}
