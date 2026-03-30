package com.eclinic.core.network

import com.eclinic.core.common.model.Medication
import retrofit2.http.GET
import retrofit2.http.Query

interface MedicationService {
    @GET("api/v1/clinical/medications/search")
    suspend fun searchMedications(
        @Query("q") query: String
    ): List<Medication>

    @GET("api/v1/clinical/medications/nappi/{nappiCode}")
    suspend fun getMedicationByNappi(@Query("nappiCode") nappiCode: String): Medication
}
