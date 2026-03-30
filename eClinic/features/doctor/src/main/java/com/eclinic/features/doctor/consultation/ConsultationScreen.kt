package com.eclinic.features.doctor.consultation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.Diagnosis
import com.eclinic.core.common.model.SoapNote

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConsultationScreen(
    patientId: String,
    onBack: () -> Unit,
    onSaveSuccess: () -> Unit,
    viewModel: ConsultationViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(patientId) {
        viewModel.onIntent(ConsultationIntent.StartConsultation(patientId))
    }

    LaunchedEffect(state) {
        if (state is ConsultationState.Saved) {
            onSaveSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Consultation") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (state is ConsultationState.Active) {
                        IconButton(onClick = { viewModel.onIntent(ConsultationIntent.SaveConsultation) }) {
                            Icon(Icons.Default.Save, contentDescription = "Save")
                        }
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
                is ConsultationState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is ConsultationState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(ConsultationIntent.StartConsultation(patientId)) }) {
                            Text("Retry")
                        }
                    }
                }
                is ConsultationState.Active -> {
                    ConsultationForm(
                        consultation = currentState.consultation,
                        onSoapNoteChange = { viewModel.onIntent(ConsultationIntent.UpdateSoapNote(it)) },
                        onAddDiagnosis = { viewModel.onIntent(ConsultationIntent.AddDiagnosis(it)) },
                        onRemoveDiagnosis = { viewModel.onIntent(ConsultationIntent.RemoveDiagnosis(it)) }
                    )
                }
                else -> {}
            }
        }
    }
}

@Composable
fun ConsultationForm(
    consultation: com.eclinic.core.common.model.Consultation,
    onSoapNoteChange: (SoapNote) -> Unit,
    onAddDiagnosis: (Diagnosis) -> Unit,
    onRemoveDiagnosis: (String) -> Unit
) {
    val scrollState = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(scrollState),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        SoapSection(
            title = "Subjective",
            value = consultation.soapNote.subjective,
            onValueChange = { onSoapNoteChange(consultation.soapNote.copy(subjective = it)) },
            placeholder = "Patient's chief complaint and history..."
        )

        SoapSection(
            title = "Objective",
            value = consultation.soapNote.objective,
            onValueChange = { onSoapNoteChange(consultation.soapNote.copy(objective = it)) },
            placeholder = "Physical examination findings..."
        )

        DiagnosisSection(
            diagnoses = consultation.diagnoses,
            onAddDiagnosis = onAddDiagnosis,
            onRemoveDiagnosis = onRemoveDiagnosis
        )

        SoapSection(
            title = "Assessment",
            value = consultation.soapNote.assessment,
            onValueChange = { onSoapNoteChange(consultation.soapNote.copy(assessment = it)) },
            placeholder = "Clinical impression and reasoning..."
        )

        SoapSection(
            title = "Plan",
            value = consultation.soapNote.plan,
            onValueChange = { onSoapNoteChange(consultation.soapNote.copy(plan = it)) },
            placeholder = "Treatment plan, medications, and follow-up..."
        )

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
fun SoapSection(
    title: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String
) {
    Column {
        Text(text = title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(placeholder) },
            minLines = 3
        )
    }
}

@Composable
fun DiagnosisSection(
    diagnoses: List<Diagnosis>,
    onAddDiagnosis: (Diagnosis) -> Unit,
    onRemoveDiagnosis: (String) -> Unit
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = "Diagnoses (ICD-10)", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            IconButton(onClick = {
                // In a real app, this would open a search dialog
                onAddDiagnosis(Diagnosis("J00", "Acute nasopharyngitis [common cold]"))
            }) {
                Icon(Icons.Default.Add, contentDescription = "Add Diagnosis")
            }
        }
        
        if (diagnoses.isEmpty()) {
            Text(
                text = "No diagnoses added yet",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline
            )
        } else {
            diagnoses.forEach { diagnosis ->
                DiagnosisChip(diagnosis, onRemoveDiagnosis)
            }
        }
    }
}

@Composable
fun DiagnosisChip(diagnosis: Diagnosis, onRemove: (String) -> Unit) {
    AssistChip(
        onClick = { },
        label = { Text("${diagnosis.icd10Code}: ${diagnosis.description}") },
        trailingIcon = {
            IconButton(onClick = { onRemove(diagnosis.icd10Code) }, modifier = Modifier.size(18.dp)) {
                Icon(Icons.Default.Close, contentDescription = "Remove", modifier = Modifier.size(14.dp))
            }
        },
        modifier = Modifier.padding(vertical = 4.dp)
    )
}
