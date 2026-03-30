package com.eclinic.features.doctor.data.repository

import com.eclinic.core.common.model.Medication
import com.eclinic.core.network.MedicationService
import com.eclinic.features.doctor.domain.repository.MedicationRepository
import javax.inject.Inject

class MedicationRepositoryImpl @Inject constructor(
    private val medicationService: MedicationService
) : MedicationRepository {

    override suspend fun searchMedications(query: String): Result<List<Medication>> {
        return try {
            val medications = medicationService.searchMedications(query)
            Result.success(medications)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMedicationByNappi(nappiCode: String): Result<Medication> {
        return try {
            val medication = medicationService.getMedicationByNappi(nappiCode)
            Result.success(medication)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
