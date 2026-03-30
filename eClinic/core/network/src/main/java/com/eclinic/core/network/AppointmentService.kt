package com.eclinic.core.network

import com.eclinic.core.common.model.AvailableAppointments
import com.eclinic.core.common.model.BookAppointmentRequest
import com.eclinic.core.common.model.BookAppointmentResponse
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

interface AppointmentService {
    @GET("api/v1/appointments/available")
    suspend fun getAvailableSlots(
        @Query("facilityId") facilityId: String,
        @Query("date") date: Long // timestamp for the day
    ): AvailableAppointments

    @POST("api/v1/appointments/book")
    suspend fun bookAppointment(
        @Body request: BookAppointmentRequest
    ): BookAppointmentResponse
}
