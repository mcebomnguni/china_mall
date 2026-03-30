package com.eclinic.features.admin.data.repository

import com.eclinic.core.common.model.InventoryItem
import com.eclinic.core.common.model.StaffMember
import com.eclinic.core.network.AdminService
import com.eclinic.features.admin.domain.repository.AdminRepository
import javax.inject.Inject

class AdminRepositoryImpl @Inject constructor(
    private val adminService: AdminService
) : AdminRepository {

    override suspend fun getStaff(facilityId: String): Result<List<StaffMember>> {
        return try {
            val staff = adminService.getStaff(facilityId)
            Result.success(staff)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun addStaff(staff: StaffMember): Result<Unit> {
        return try {
            adminService.addStaff(staff)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getInventory(facilityId: String): Result<List<InventoryItem>> {
        return try {
            val inventory = adminService.getInventory(facilityId)
            Result.success(inventory)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateStock(itemId: String, level: Int): Result<Unit> {
        return try {
            adminService.updateStock(itemId, level)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
