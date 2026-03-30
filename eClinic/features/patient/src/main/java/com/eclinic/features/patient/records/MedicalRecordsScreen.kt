package com.eclinic.features.patient.records

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.MedicalRecord
import com.eclinic.core.common.model.RecordType
import com.eclinic.features.patient.dashboard.PatientDashboardIntent
import com.eclinic.features.patient.dashboard.PatientDashboardState
import com.eclinic.features.patient.dashboard.PatientDashboardViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MedicalRecordsScreen(
    onBack: () -> Unit,
    viewModel: PatientDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.onIntent(PatientDashboardIntent.LoadMedicalRecords)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Medical Records") },
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
                is PatientDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is PatientDashboardState.Error -> {
                    Text(
                        text = currentState.message,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                is PatientDashboardState.Success -> {
                    if (currentState.records.isEmpty()) {
                        Text(
                            text = "No medical records found.",
                            modifier = Modifier.align(Alignment.Center)
                        )
                    } else {
                        LazyColumn(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            items(currentState.records) { record ->
                                MedicalRecordCard(record)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MedicalRecordCard(record: MedicalRecord) {
    val dateStr = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(record.date))
    val (icon, color) = when (record.type) {
        RecordType.CONSULTATION -> Icons.Default.ChatBubble to MaterialTheme.colorScheme.primary
        RecordType.LAB_RESULT -> Icons.Default.Science to Color(0xFF00A651)
        RecordType.PRESCRIPTION -> Icons.Default.Medication to Color(0xFF1976D2)
        RecordType.REFERRAL -> Icons.Default.Share to Color(0xFFFFA000)
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = color)
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(record.title, fontWeight = FontWeight.Bold)
                    Text(dateStr, style = MaterialTheme.typography.bodySmall)
                }
                Text(record.type.name, style = MaterialTheme.typography.labelSmall, color = color)
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(record.content, style = MaterialTheme.typography.bodyMedium)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Doctor: ${record.doctorName}",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.outline
            )
        }
    }
}
