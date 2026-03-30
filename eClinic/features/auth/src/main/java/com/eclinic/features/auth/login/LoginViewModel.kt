package com.eclinic.features.auth.login

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.features.auth.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _state = MutableStateFlow<LoginState>(LoginState.Initial)
    val state: StateFlow<LoginState> = _state.asStateFlow()

    fun onIntent(intent: LoginIntent) {
        when (intent) {
            is LoginIntent.LoginClicked -> login(intent.email, intent.password)
            is LoginIntent.BiometricLoginRequested -> biometricLogin()
            LoginIntent.DismissError -> _state.value = LoginState.Initial
        }
    }

    private fun login(email: String, password: String) {
        viewModelScope.launch {
            _state.value = LoginState.Loading
            authRepository.login(email, password)
                .onSuccess { response ->
                    _state.value = LoginState.Success(response.user)
                }
                .onFailure { error ->
                    _state.value = LoginState.Error(error.message ?: "Authentication failed")
                }
        }
    }

    private fun biometricLogin() {
        // Implementation for biometric login will follow once BiometricPrompt is integrated
        _state.value = LoginState.Error("Biometric login not yet implemented")
    }
}
