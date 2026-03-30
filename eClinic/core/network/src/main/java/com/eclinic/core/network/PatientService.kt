package com.eclinic.core.network

import com.eclinic.core.common.model.PatientDashboardData
import com.eclinic.core.common.model.MedicalRecord
import retrofit2.http.GET
import retrofit2.http.Path

interface PatientService {
    @GET("api/v1/patient/dashboard/{patientId}")
    suspend fun getDashboardData(@Path("patientId") patientId: String): PatientDashboardData

    @GET("api/v1/patient/records/{patientId}")
    suspend fun getMedicalRecords(@Path("patientId") patientId: String): List<MedicalRecord>
}
