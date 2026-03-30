package com.eclinic.features.pharmacy.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Medication
import androidx.compose.material.icons.filled.Refresh
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
import com.eclinic.core.common.model.PrescriptionToDispense
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PharmacyDashboardScreen(
    viewModel: PharmacyDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Pharmacy Dispensing Queue") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(PharmacyDashboardIntent.Refresh) }) {
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
                is PharmacyDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is PharmacyDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(PharmacyDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is PharmacyDashboardState.Success -> {
                    PrescriptionQueue(
                        prescriptions = currentState.pendingPrescriptions,
                        onDispense = { id, items -> 
                            viewModel.onIntent(PharmacyDashboardIntent.DispenseMedication(id, items)) 
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun PrescriptionQueue(
    prescriptions: List<PrescriptionToDispense>,
    onDispense: (String, Map<String, Int>) -> Unit
) {
    if (prescriptions.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No pending prescriptions")
        }
    } else {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(prescriptions) { prescription ->
                PrescriptionCard(prescription, onDispense)
            }
        }
    }
}

@Composable
fun PrescriptionCard(
    prescription: PrescriptionToDispense,
    onDispense: (String, Map<String, Int>) -> Unit
) {
    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = prescription.patientName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Dr. ${prescription.doctorName}",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                val dateStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(prescription.dateIssued))
                Text(text = dateStr, style = MaterialTheme.typography.labelSmall)
            }

            Divider(modifier = Modifier.padding(vertical = 12.dp))

            prescription.items.forEach { item ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(item.medication.name, style = MaterialTheme.typography.bodyMedium)
                        Text(
                            text = "${item.dosage} | ${item.frequency} | ${item.duration}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                    Icon(Icons.Default.Medication, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = { 
                    // Simplified: dispensing all items at full requested quantity
                    val dispenseMap = prescription.items.associate { it.medication.nappiCode to 1 } 
                    onDispense(prescription.prescriptionId, dispenseMap)
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Confirm Dispensing")
            }
        }
    }
}
