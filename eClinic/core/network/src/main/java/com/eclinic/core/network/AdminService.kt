package com.eclinic.core.network

import com.eclinic.core.common.model.StaffMember
import com.eclinic.core.common.model.InventoryItem
import retrofit2.http.*

interface AdminService {
    @GET("api/v1/admin/staff/{facilityId}")
    suspend fun getStaff(@Path("facilityId") facilityId: String): List<StaffMember>

    @POST("api/v1/admin/staff")
    suspend fun addStaff(@Body staff: StaffMember)

    @GET("api/v1/admin/inventory/{facilityId}")
    suspend fun getInventory(@Path("facilityId") facilityId: String): List<InventoryItem>

    @PUT("api/v1/admin/inventory/{itemId}")
    suspend fun updateStock(@Path("itemId") itemId: String, @Query("newLevel") level: Int)
}
