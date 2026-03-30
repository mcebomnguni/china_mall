package com.eclinic.features.pharmacy.data.repository

import com.eclinic.core.common.model.DispenseRecord
import com.eclinic.core.common.model.PrescriptionToDispense
import com.eclinic.core.network.PharmacyService
import com.eclinic.features.pharmacy.domain.repository.PharmacyRepository
import javax.inject.Inject

class PharmacyRepositoryImpl @Inject constructor(
    private val pharmacyService: PharmacyService
) : PharmacyRepository {

    override suspend fun getPendingPrescriptions(facilityId: String): Result<List<PrescriptionToDispense>> {
        return try {
            val prescriptions = pharmacyService.getPendingPrescriptions(facilityId)
            Result.success(prescriptions)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun recordDispense(record: DispenseRecord): Result<Unit> {
        return try {
            pharmacyService.recordDispense(record)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
