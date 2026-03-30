package com.eclinic.features.admin.dashboard

import com.eclinic.core.common.model.InventoryItem
import com.eclinic.core.common.model.StaffMember

sealed interface AdminDashboardState {
    object Loading : AdminDashboardState
    data class Success(
        val staff: List<StaffMember>,
        val inventory: List<InventoryItem>,
        val activeTab: AdminTab = AdminTab.STAFF
    ) : AdminDashboardState
    data class Error(val message: String) : AdminDashboardState
}

enum class AdminTab {
    STAFF, INVENTORY, CONFIG
}

sealed interface AdminDashboardIntent {
    object Refresh : AdminDashboardIntent
    data class ChangeTab(val tab: AdminTab) : AdminDashboardIntent
    data class ToggleStaffStatus(val staffId: String) : AdminDashboardIntent
    data class UpdateStockLevel(val itemId: String, val newLevel: Int) : AdminDashboardIntent
}
