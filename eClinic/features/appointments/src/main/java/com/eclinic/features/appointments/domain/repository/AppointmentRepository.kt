package com.eclinic.features.appointments.domain.repository

import com.eclinic.core.common.model.AvailableAppointments
import com.eclinic.core.common.model.BookAppointmentRequest
import com.eclinic.core.common.model.BookAppointmentResponse

interface AppointmentRepository {
    suspend fun getAvailableSlots(facilityId: String, date: Long): Result<AvailableAppointments>
    suspend fun bookAppointment(request: BookAppointmentRequest): Result<BookAppointmentResponse>
}
