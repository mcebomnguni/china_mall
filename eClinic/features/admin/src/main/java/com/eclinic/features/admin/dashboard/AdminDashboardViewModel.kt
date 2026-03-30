package com.eclinic.features.admin.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.features.admin.domain.repository.AdminRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AdminDashboardViewModel @Inject constructor(
    private val repository: AdminRepository
) : ViewModel() {

    private val _state = MutableStateFlow<AdminDashboardState>(AdminDashboardState.Loading)
    val state: StateFlow<AdminDashboardState> = _state.asStateFlow()

    private val facilityId = "fac-456" // Default for MVP

    init {
        loadDashboardData()
    }

    fun onIntent(intent: AdminDashboardIntent) {
        when (intent) {
            AdminDashboardIntent.Refresh -> loadDashboardData()
            is AdminDashboardIntent.ChangeTab -> {
                val currentState = _state.value
                if (currentState is AdminDashboardState.Success) {
                    _state.value = currentState.copy(activeTab = intent.tab)
                }
            }
            is AdminDashboardIntent.ToggleStaffStatus -> {
                // Implementation for toggling staff status
            }
            is AdminDashboardIntent.UpdateStockLevel -> {
                updateStock(intent.itemId, intent.newLevel)
            }
        }
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            _state.value = AdminDashboardState.Loading
            val staffResult = repository.getStaff(facilityId)
            val inventoryResult = repository.getInventory(facilityId)

            if (staffResult.isSuccess && inventoryResult.isSuccess) {
                _state.value = AdminDashboardState.Success(
                    staff = staffResult.getOrThrow(),
                    inventory = inventoryResult.getOrThrow()
                )
            } else {
                _state.value = AdminDashboardState.Error("Failed to load dashboard data")
            }
        }
    }

    private fun updateStock(itemId: String, newLevel: Int) {
        viewModelScope.launch {
            repository.updateStock(itemId, newLevel)
                .onSuccess { loadDashboardData() }
        }
    }
}
