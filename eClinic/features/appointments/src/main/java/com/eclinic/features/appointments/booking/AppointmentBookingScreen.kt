package com.eclinic.features.appointments.booking

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.AppointmentSlot
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppointmentBookingScreen(
    patientId: String,
    facilityId: String,
    onBack: () -> Unit,
    onBookingSuccess: () -> Unit,
    viewModel: AppointmentBookingViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    var selectedDate by remember { mutableStateOf(System.currentTimeMillis()) }

    LaunchedEffect(selectedDate) {
        viewModel.onIntent(AppointmentBookingIntent.LoadAvailableSlots(facilityId, selectedDate))
    }

    LaunchedEffect(state) {
        if (state is AppointmentBookingState.BookingSuccess) {
            onBookingSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Book Appointment") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (val currentState = state) {
                is AppointmentBookingState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is AppointmentBookingState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(AppointmentBookingIntent.LoadAvailableSlots(facilityId, selectedDate)) }) {
                            Text("Retry")
                        }
                    }
                }
                is AppointmentBookingState.SlotsLoaded -> {
                    BookingContent(
                        slots = currentState.availableAppointments.slots,
                        selectedDate = currentState.selectedDate,
                        onSlotSelected = { slot ->
                            viewModel.onIntent(
                                AppointmentBookingIntent.SelectSlotAndBook(
                                    patientId = patientId,
                                    facilityId = facilityId,
                                    slot = slot
                                )
                            )
                        }
                    )
                }
                else -> {
                    // Initial or success states handled by LaunchedEffect or elsewhere
                }
            }
        }
    }
}

@Composable
fun BookingContent(
    slots: List<AppointmentSlot>,
    selectedDate: Long,
    onSlotSelected: (AppointmentSlot) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Date Display
        val dateStr = SimpleDateFormat("EEEE, dd MMM yyyy", Locale.getDefault()).format(Date(selectedDate))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.DateRange, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.width(8.dp))
            Text(text = dateStr, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(text = "Available Slots", style = MaterialTheme.typography.titleSmall)
        Spacer(modifier = Modifier.height(16.dp))

        if (slots.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No available slots for this date.")
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(slots) { slot ->
                    SlotChip(slot, onSlotSelected)
                }
            }
        }
    }
}

@Composable
fun SlotChip(slot: AppointmentSlot, onClick: (AppointmentSlot) -> Unit) {
    val timeStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(slot.startTime))
    
    OutlinedButton(
        onClick = { if (slot.isAvailable) onClick(slot) },
        enabled = slot.isAvailable,
        shape = MaterialTheme.shapes.medium,
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = if (slot.isAvailable) MaterialTheme.colorScheme.primary else Color.Gray
        )
    ) {
        Text(text = timeStr)
    }
}
