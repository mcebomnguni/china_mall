package com.eclinic.core.network

import com.eclinic.core.common.model.LoginResponse
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthService {
    @POST("api/v1/auth/login")
    suspend fun login(@Body credentials: Map<String, String>): LoginResponse

    @POST("api/v1/auth/logout")
    suspend fun logout()
}
