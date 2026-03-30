package com.eclinic.features.admin.domain.repository

import com.eclinic.core.common.model.InventoryItem
import com.eclinic.core.common.model.StaffMember

interface AdminRepository {
    suspend fun getStaff(facilityId: String): Result<List<StaffMember>>
    suspend fun addStaff(staff: StaffMember): Result<Unit>
    suspend fun getInventory(facilityId: String): Result<List<InventoryItem>>
    suspend fun updateStock(itemId: String, level: Int): Result<Unit>
}
