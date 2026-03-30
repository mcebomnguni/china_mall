package com.eclinic.features.appointments.booking

import com.eclinic.core.common.model.AppointmentSlot
import com.eclinic.core.common.model.AvailableAppointments

sealed interface AppointmentBookingState {
    object Initial : AppointmentBookingState
    object Loading : AppointmentBookingState
    data class SlotsLoaded(
        val availableAppointments: AvailableAppointments,
        val selectedDate: Long
    ) : AppointmentBookingState
    data class BookingSuccess(val message: String) : AppointmentBookingState
    data class Error(val message: String) : AppointmentBookingState
}

sealed interface AppointmentBookingIntent {
    data class LoadAvailableSlots(val facilityId: String, val date: Long) : AppointmentBookingIntent
    data class SelectSlotAndBook(
        val patientId: String,
        val facilityId: String,
        val slot: AppointmentSlot
    ) : AppointmentBookingIntent
}
