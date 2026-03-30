package com.eclinic.features.doctor.dashboard

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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DoctorDashboardScreen(
    onPatientClick: (String) -> Unit,
    viewModel: DoctorDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Doctor Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(DoctorDashboardIntent.Refresh) }) {
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
                is DoctorDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is DoctorDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(DoctorDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is DoctorDashboardState.Success -> {
                    DashboardContent(
                        state = currentState,
                        onPatientClick = onPatientClick,
                        onDismissAlert = { viewModel.onIntent(DoctorDashboardIntent.DismissAlert(it)) }
                    )
                }
            }
        }
    }
}

@Composable
fun DashboardContent(
    state: DoctorDashboardState.Success,
    onPatientClick: (String) -> Unit,
    onDismissAlert: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Alerts Section
        if (state.alerts.isNotEmpty()) {
            item {
                SectionHeader("Critical Alerts", Icons.Default.Warning, MaterialTheme.colorScheme.error)
            }
            items(state.alerts) { alert ->
                AlertItem(alert, onDismissAlert)
            }
        }

        // Today's Queue Section
        item {
            SectionHeader("Today's Queue", Icons.Default.Groups, MaterialTheme.colorScheme.primary)
        }
        items(state.queue) { item ->
            QueueItem(item, onPatientClick)
        }

        // Appointments Section
        item {
            SectionHeader("Upcoming Appointments", Icons.Default.Event, MaterialTheme.colorScheme.secondary)
        }
        items(state.appointments) { appointment ->
            AppointmentItem(appointment)
        }

        // Tasks Section
        item {
            SectionHeader("Pending Tasks", Icons.Default.Assignment, Color(0xFFFFA000))
        }
        items(state.pendingTasks) { task ->
            TaskItem(task)
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
fun AlertItem(alert: ClinicalAlert, onDismiss: (String) -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(alert.patientName, fontWeight = FontWeight.Bold)
                Text(alert.message, style = MaterialTheme.typography.bodySmall)
            }
            IconButton(onClick = { onDismiss(alert.id) }) {
                Icon(Icons.Default.Close, contentDescription = "Dismiss")
            }
        }
    }
}

@Composable
fun QueueItem(item: PatientQueueItem, onClick: (String) -> Unit) {
    ElevatedCard(
        onClick = { onClick(item.patientId) },
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(item.patientName, style = MaterialTheme.typography.titleMedium)
                Text("Reason: ${item.reasonForVisit}", style = MaterialTheme.typography.bodySmall)
            }
            PriorityBadge(item.priority)
            Spacer(modifier = Modifier.width(8.dp))
            Text("${item.waitingTimeMinutes}m", style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
fun PriorityBadge(priority: Priority) {
    val color = when (priority) {
        Priority.EMERGENCY -> Color.Red
        Priority.URGENT -> Color(0xFFFFA000)
        Priority.ROUTINE -> Color(0xFF00A651)
    }
    Surface(
        color = color,
        shape = RoundedCornerShape(4.dp)
    ) {
        Text(
            text = priority.name,
            color = Color.White,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelSmall
        )
    }
}

@Composable
fun AppointmentItem(appointment: Appointment) {
    OutlinedCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(appointment.time, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(appointment.patientName)
                Text(appointment.type, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
fun TaskItem(task: Task) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Checkbox(checked = task.isCompleted, onCheckedChange = {})
        Column {
            Text(task.title)
            Text("Deadline: ${task.deadline}", style = MaterialTheme.typography.bodySmall)
        }
    }
}
