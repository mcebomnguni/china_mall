package com.eclinic.features.doctor.domain.repository

import com.eclinic.core.common.model.Medication

interface MedicationRepository {
    suspend fun searchMedications(query: String): Result<List<Medication>>
    suspend fun getMedicationByNappi(nappiCode: String): Result<Medication>
}
