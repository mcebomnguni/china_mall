package com.eclinic.features.auth.login

import com.eclinic.core.common.model.User

sealed interface LoginState {
    object Initial : LoginState
    object Loading : LoginState
    data class Success(val user: User) : LoginState
    data class Error(val message: String) : LoginState
}

sealed interface LoginIntent {
    data class LoginClicked(val email: String, val password: String) : LoginIntent
    object BiometricLoginRequested : LoginIntent
    object DismissError : LoginIntent
}
