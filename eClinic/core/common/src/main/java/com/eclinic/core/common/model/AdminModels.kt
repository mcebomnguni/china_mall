package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class StaffMember(
    val id: String,
    val firstName: String,
    val lastName: String,
    val role: UserRole,
    val email: String,
    val isActive: Boolean = true
)

@Serializable
data class InventoryItem(
    val id: String,
    val name: String,
    val category: String, // e.g., "Medication", "Surgical", "Equipment"
    val stockLevel: Int,
    val minStockLevel: Int,
    val unit: String // e.g., "Tablets", "Boxes", "Vials"
)
