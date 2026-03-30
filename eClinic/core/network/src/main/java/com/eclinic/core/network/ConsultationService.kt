package com.eclinic.core.network

import com.eclinic.core.common.model.Consultation
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.Path

interface ConsultationService {
    @POST("api/v1/consultations/start/{patientId}")
    suspend fun startConsultation(@Path("patientId") patientId: String): Consultation

    @POST("api/v1/consultations/save")
    suspend fun saveConsultation(@Body consultation: Consultation)
}
