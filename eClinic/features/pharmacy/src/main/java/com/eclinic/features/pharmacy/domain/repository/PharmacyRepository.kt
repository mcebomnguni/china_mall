package com.eclinic.features.pharmacy.domain.repository

import com.eclinic.core.common.model.DispenseRecord
import com.eclinic.core.common.model.PrescriptionToDispense

interface PharmacyRepository {
    suspend fun getPendingPrescriptions(facilityId: String): Result<List<PrescriptionToDispense>>
    suspend fun recordDispense(record: DispenseRecord): Result<Unit>
}
