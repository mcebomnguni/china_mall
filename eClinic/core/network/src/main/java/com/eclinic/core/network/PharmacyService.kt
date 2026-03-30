package com.eclinic.core.network

import com.eclinic.core.common.model.DispenseRecord
import com.eclinic.core.common.model.PrescriptionToDispense
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path

interface PharmacyService {
    @GET("api/v1/pharmacy/prescriptions/{facilityId}")
    suspend fun getPendingPrescriptions(@Path("facilityId") facilityId: String): List<PrescriptionToDispense>

    @POST("api/v1/pharmacy/dispense")
    suspend fun recordDispense(@Body record: DispenseRecord)
}
