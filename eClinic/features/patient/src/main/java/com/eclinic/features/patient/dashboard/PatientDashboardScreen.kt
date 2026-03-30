package com.eclinic.features.patient.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.*
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PatientDashboardScreen(
    onBookAppointment: () -> Unit,
    onViewRecords: () -> Unit,
    viewModel: PatientDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Health Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(PatientDashboardIntent.Refresh) }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
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
                is PatientDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is PatientDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(PatientDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is PatientDashboardState.Success -> {
                    PatientDashboardContent(
                        data = currentState.dashboardData,
                        onBookAppointment = onBookAppointment,
                        onViewRecords = onViewRecords
                    )
                }
            }
        }
    }
}

@Composable
fun PatientDashboardContent(
    data: PatientDashboardData,
    onBookAppointment: () -> Unit,
    onViewRecords: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Next Appointment Section
        item {
            NextAppointmentCard(data.nextAppointment, onBookAppointment)
        }

        // Active Medications Section
        item {
            SectionHeader("Active Medications", Icons.Default.Medication, MaterialTheme.colorScheme.primary)
        }
        if (data.activeMedications.isEmpty()) {
            item { Text("No active medications", style = MaterialTheme.typography.bodyMedium) }
        } else {
            items(data.activeMedications) { medication ->
                MedicationItem(medication)
            }
        }

        // Recent Visit Summary Section
        item {
            SectionHeader("Recent Visit", Icons.Default.History, MaterialTheme.colorScheme.secondary)
        }
        item {
            RecentVisitCard(data.recentVisitSummary, onViewRecords)
        }

        // Health Reminders Section
        if (data.healthReminders.isNotEmpty()) {
            item {
                SectionHeader("Reminders", Icons.Default.NotificationsActive, Color(0xFFFFA000))
            }
            items(data.healthReminders) { reminder ->
                ReminderItem(reminder)
            }
        }
    }
}

@Composable
fun NextAppointmentCard(appointment: Appointment?, onBookClick: () -> Unit) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Upcoming Appointment",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            if (appointment != null) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Event, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("${appointment.time} - ${appointment.type}")
                }
                Text("Facility: Clinic Central", style = MaterialTheme.typography.bodySmall)
            } else {
                Text("No upcoming appointments")
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = onBookClick) {
                    Text("Book Appointment")
                }
            }
        }
    }
}

@Composable
fun SectionHeader(title: String, icon: ImageVector, color: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 8.dp)
    ) {
        Icon(icon, contentDescription = null, tint = color)
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = color
        )
    }
}

@Composable
fun MedicationItem(medication: String) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF00A651))
            Spacer(modifier = Modifier.width(12.dp))
            Text(medication, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

@Composable
fun RecentVisitCard(summary: VisitSummary?, onViewRecords: () -> Unit) {
    OutlinedCard(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            if (summary != null) {
                val dateStr = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(summary.date))
                Text(dateStr, fontWeight = FontWeight.Bold)
                Text(summary.facilityName, style = MaterialTheme.typography.bodySmall)
                Spacer(modifier = Modifier.height(8.dp))
                Text("Diagnosis: ${summary.diagnosis}")
                Text("Plan: ${summary.plan}", style = MaterialTheme.typography.bodySmall)
                Spacer(modifier = Modifier.height(8.dp))
                TextButton(onClick = onViewRecords) {
                    Text("View Full Records")
                }
            } else {
                Text("No recent visits found")
            }
        }
    }
}

@Composable
fun ReminderItem(reminder: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.Info, contentDescription = null, tint = Color(0xFFFFA000))
        Spacer(modifier = Modifier.width(12.dp))
        Text(reminder, style = MaterialTheme.typography.bodyMedium)
    }
}
