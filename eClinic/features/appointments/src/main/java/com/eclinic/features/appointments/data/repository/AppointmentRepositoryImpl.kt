package com.eclinic.features.appointments.data.repository

import com.eclinic.core.common.model.AvailableAppointments
import com.eclinic.core.common.model.BookAppointmentRequest
import com.eclinic.core.common.model.BookAppointmentResponse
import com.eclinic.core.network.AppointmentService
import com.eclinic.features.appointments.domain.repository.AppointmentRepository
import javax.inject.Inject

class AppointmentRepositoryImpl @Inject constructor(
    private val appointmentService: AppointmentService
) : AppointmentRepository {

    override suspend fun getAvailableSlots(facilityId: String, date: Long): Result<AvailableAppointments> {
        return try {
            val slots = appointmentService.getAvailableSlots(facilityId, date)
            Result.success(slots)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun bookAppointment(request: BookAppointmentRequest): Result<BookAppointmentResponse> {
        return try {
            val response = appointmentService.bookAppointment(request)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
