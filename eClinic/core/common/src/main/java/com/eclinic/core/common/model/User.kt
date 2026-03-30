package com.eclinic.core.common.model

import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    val firstName: String,
    val lastName: String,
    val email: String,
    val role: UserRole,
    val facilityId: String? = null,
    val districtId: String? = null,
    val regionId: String? = null,
    val provinceId: String? = null
)
