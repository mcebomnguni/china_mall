package com.eclinic.core.network

import com.eclinic.core.database.entity.ConsultationEntity
import com.eclinic.core.database.entity.PatientEntity
import com.eclinic.core.database.entity.VitalsEntity
import kotlinx.serialization.Serializable
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

@Serializable
data class SyncPushRequest(
    val patients: List<PatientEntity> = emptyList(),
    val consultations: List<ConsultationEntity> = emptyList(),
    val vitals: List<VitalsEntity> = emptyList()
)

@Serializable
data class SyncPushResponse(
    val acceptedIds: List<String>,
    val conflicts: List<String> // Simplified for MVP
)

@Serializable
data class SyncPullResponse(
    val patients: List<PatientEntity>,
    val consultations: List<ConsultationEntity>,
    val vitals: List<VitalsEntity>,
    val serverTime: Long
)

interface SyncApi {
    @POST("api/v1/sync/push")
    suspend fun push(@Body request: SyncPushRequest): SyncPushResponse

    @GET("api/v1/sync/pull")
    suspend fun pull(@Query("since") since: Long): SyncPullResponse
}
