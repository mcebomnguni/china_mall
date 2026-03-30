package com.eclinic.features.nurse.vitals

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VitalsScreen(
    patientId: String,
    onBack: () -> Unit,
    onSuccess: () -> Unit,
    viewModel: VitalsViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    var systolicBP by remember { mutableStateOf("") }
    var diastolicBP by remember { mutableStateOf("") }
    var heartRate by remember { mutableStateOf("") }
    var temperature by remember { mutableStateOf("") }
    var spo2 by remember { mutableStateOf("") }
    var weight by remember { mutableStateOf("") }
    var height by remember { mutableStateOf("") }
    var bloodGlucose by remember { mutableStateOf("") }

    LaunchedEffect(state) {
        if (state is VitalsState.Success) {
            onSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Vitals") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            viewModel.onIntent(
                                VitalsIntent.SaveVitals(
                                    patientId = patientId,
                                    systolicBP = systolicBP,
                                    diastolicBP = diastolicBP,
                                    heartRate = heartRate,
                                    temperature = temperature,
                                    spo2 = spo2,
                                    weight = weight,
                                    height = height,
                                    bloodGlucose = bloodGlucose
                                )
                            )
                        },
                        enabled = state !is VitalsState.Loading
                    ) {
                        Icon(Icons.Default.Save, contentDescription = "Save")
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "Patient ID: $patientId",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    VitalsField(
                        value = systolicBP,
                        onValueChange = { systolicBP = it },
                        label = "Systolic BP",
                        modifier = Modifier.weight(1f)
                    )
                    VitalsField(
                        value = diastolicBP,
                        onValueChange = { diastolicBP = it },
                        label = "Diastolic BP",
                        modifier = Modifier.weight(1f)
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    VitalsField(
                        value = heartRate,
                        onValueChange = { heartRate = it },
                        label = "Heart Rate",
                        modifier = Modifier.weight(1f)
                    )
                    VitalsField(
                        value = temperature,
                        onValueChange = { temperature = it },
                        label = "Temp (°C)",
                        modifier = Modifier.weight(1f)
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    VitalsField(
                        value = spo2,
                        onValueChange = { spo2 = it },
                        label = "SpO2 (%)",
                        modifier = Modifier.weight(1f)
                    )
                    VitalsField(
                        value = bloodGlucose,
                        onValueChange = { bloodGlucose = it },
                        label = "Glucose",
                        modifier = Modifier.weight(1f)
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    VitalsField(
                        value = weight,
                        onValueChange = { weight = it },
                        label = "Weight (kg)",
                        modifier = Modifier.weight(1f)
                    )
                    VitalsField(
                        value = height,
                        onValueChange = { height = it },
                        label = "Height (cm)",
                        modifier = Modifier.weight(1f)
                    )
                }

                if (state is VitalsState.Error) {
                    Text(
                        text = (state as VitalsState.Error).message,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }

            if (state is VitalsState.Loading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
fun VitalsField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        modifier = modifier
    )
}
