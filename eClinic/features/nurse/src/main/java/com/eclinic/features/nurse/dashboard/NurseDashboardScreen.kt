package com.eclinic.features.nurse.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.PatientQueueItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NurseDashboardScreen(
    onTriageClick: (String) -> Unit,
    onVitalsClick: (String) -> Unit,
    onMedicationClick: (String) -> Unit,
    viewModel: NurseDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Nurse Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(NurseDashboardIntent.Refresh) }) {
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
                is NurseDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is NurseDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(NurseDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is NurseDashboardState.Success -> {
                    NurseDashboardContent(
                        state = currentState,
                        onTriageClick = onTriageClick,
                        onVitalsClick = onVitalsClick,
                        onMedicationClick = onMedicationClick
                    )
                }
            }
        }
    }
}

@Composable
fun NurseDashboardContent(
    state: NurseDashboardState.Success,
    onTriageClick: (String) -> Unit,
    onVitalsClick: (String) -> Unit,
    onMedicationClick: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Pending Vitals Section
        if (state.pendingVitals.isNotEmpty()) {
            item {
                SectionHeader("Pending Vitals", Icons.Default.Favorite, MaterialTheme.colorScheme.primary)
            }
            items(state.pendingVitals) { patientName ->
                PendingTaskCard(patientName, "Vitals Due", onVitalsClick)
            }
        }

        // Pending Medications Section
        if (state.pendingMedications.isNotEmpty()) {
            item {
                SectionHeader("Pending Medications", Icons.Default.Medication, Color(0xFF00A651))
            }
            items(state.pendingMedications) { patientName ->
                PendingTaskCard(patientName, "Medication Due", onMedicationClick)
            }
        }

        // Ward Overview Section
        item {
            SectionHeader("Ward Overview", Icons.Default.Bed, MaterialTheme.colorScheme.secondary)
        }
        items(state.wardOverview) { patient ->
            WardPatientCard(patient, onTriageClick)
        }
    }
}

@Composable
fun SectionHeader(title: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
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
fun PendingTaskCard(patientName: String, taskType: String, onClick: (String) -> Unit) {
    ElevatedCard(
        onClick = { onClick(patientName) },
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(patientName, style = MaterialTheme.typography.titleMedium)
                Text(taskType, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
            }
            Icon(Icons.Default.ChevronRight, contentDescription = null)
        }
    }
}

@Composable
fun WardPatientCard(patient: PatientQueueItem, onClick: (String) -> Unit) {
    OutlinedCard(
        onClick = { onClick(patient.patientId) },
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(patient.patientName, style = MaterialTheme.typography.titleMedium)
                Text("Reason: ${patient.reasonForVisit}", style = MaterialTheme.typography.bodySmall)
            }
            Text("${patient.waitingTimeMinutes}m", style = MaterialTheme.typography.labelSmall)
        }
    }
}
