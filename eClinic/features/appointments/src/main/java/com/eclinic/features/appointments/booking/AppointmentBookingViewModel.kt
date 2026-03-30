package com.eclinic.features.appointments.booking

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eclinic.core.common.model.BookAppointmentRequest
import com.eclinic.features.appointments.domain.repository.AppointmentRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AppointmentBookingViewModel @Inject constructor(
    private val repository: AppointmentRepository
) : ViewModel() {

    private val _state = MutableStateFlow<AppointmentBookingState>(AppointmentBookingState.Initial)
    val state: StateFlow<AppointmentBookingState> = _state.asStateFlow()

    fun onIntent(intent: AppointmentBookingIntent) {
        when (intent) {
            is AppointmentBookingIntent.LoadAvailableSlots -> loadSlots(intent.facilityId, intent.date)
            is AppointmentBookingIntent.SelectSlotAndBook -> bookSlot(intent)
        }
    }

    private fun loadSlots(facilityId: String, date: Long) {
        viewModelScope.launch {
            _state.value = AppointmentBookingState.Loading
            repository.getAvailableSlots(facilityId, date)
                .onSuccess { slots ->
                    _state.value = AppointmentBookingState.SlotsLoaded(slots, date)
                }
                .onFailure { error ->
                    _state.value = AppointmentBookingState.Error(error.message ?: "Failed to load slots")
                }
        }
    }

    private fun bookSlot(intent: AppointmentBookingIntent.SelectSlotAndBook) {
        viewModelScope.launch {
            _state.value = AppointmentBookingState.Loading
            val request = BookAppointmentRequest(
                patientId = intent.patientId,
                facilityId = intent.facilityId,
                slotStartTime = intent.slot.startTime
            )
            repository.bookAppointment(request)
                .onSuccess { response ->
                    if (response.success) {
                        _state.value = AppointmentBookingState.BookingSuccess("Appointment confirmed for ${response.appointmentDetails.time}")
                    } else {
                        _state.value = AppointmentBookingState.Error("Booking failed")
                    }
                }
                .onFailure { error ->
                    _state.value = AppointmentBookingState.Error(error.message ?: "Failed to book appointment")
                }
        }
    }
}
