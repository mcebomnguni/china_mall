package com.eclinic.features.nurse.domain.repository

import com.eclinic.core.common.model.NurseDashboardData
import com.eclinic.core.common.model.Vitals

interface NurseRepository {
    suspend fun getNurseDashboard(nurseId: String): Result<NurseDashboardData>
    suspend fun recordVitals(vitals: Vitals): Result<Unit>
}
