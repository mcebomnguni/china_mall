package com.eclinic.features.nurse.triage

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.eclinic.core.common.model.Discriminator
import com.eclinic.core.common.model.Mobility
import com.eclinic.core.common.model.TriageCategory

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TriageScreen(
    patientId: String,
    onBack: () -> Unit,
    onSaveSuccess: () -> Unit,
    viewModel: TriageViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(patientId) {
        viewModel.onIntent(TriageIntent.LoadPatient(patientId))
    }

    LaunchedEffect(state.isSaved) {
        if (state.isSaved) {
            onSaveSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Patient Triage (SATS)") },
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Mobility Section
                TriageSection(title = "Mobility") {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Mobility.entries.forEach { mobility ->
                            FilterChip(
                                selected = state.mobility == mobility,
                                onClick = { viewModel.onIntent(TriageIntent.UpdateMobility(mobility)) },
                                label = { Text(mobility.name.replace("_", " ").lowercase().capitalize()) }
                            )
                        }
                    }
                }

                // Trauma Section
                TriageSection(title = "Trauma") {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Is there trauma?")
                        Spacer(modifier = Modifier.width(16.dp))
                        Switch(
                            checked = state.hasTrauma,
                            onCheckedChange = { viewModel.onIntent(TriageIntent.UpdateTrauma(it)) }
                        )
                    }
                }

                // TEWS Score Section
                TriageSection(title = "TEWS Score (0-12)") {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Slider(
                            value = state.tewsScore.toFloat(),
                            onValueChange = { viewModel.onIntent(TriageIntent.UpdateTews(it.toInt())) },
                            valueRange = 0f..12f,
                            steps = 11,
                            modifier = Modifier.weight(1f)
                        )
                        Text(
                            text = state.tewsScore.toString(),
                            style = MaterialTheme.typography.headlineMedium,
                            modifier = Modifier.padding(start = 16.dp)
                        )
                    }
                }

                // Clinical Discriminators Section
                TriageSection(title = "Clinical Discriminators (Red Flags)") {
                    Column {
                        Discriminator.entries.forEach { discriminator ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Checkbox(
                                    checked = state.selectedDiscriminators.contains(discriminator),
                                    onCheckedChange = { viewModel.onIntent(TriageIntent.ToggleDiscriminator(discriminator)) }
                                )
                                Text(
                                    text = discriminator.name.replace("_", " ").lowercase().capitalize(),
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                    }
                }

                // Result Section
                if (state.result != null) {
                    TriageResultCard(
                        category = state.result!!.triageCategory,
                        action = state.result!!.recommendedAction
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Button(
                        onClick = { viewModel.onIntent(TriageIntent.CalculateResult) },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Calculate")
                    }
                    Button(
                        onClick = { viewModel.onIntent(TriageIntent.SaveTriage) },
                        modifier = Modifier.weight(1f),
                        enabled = state.result != null && !state.isLoading,
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00A651))
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), color = Color.White)
                        } else {
                            Text("Save Triage")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TriageSection(title: String, content: @Composable () -> Unit) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(8.dp))
        content()
        Divider(modifier = Modifier.padding(top = 16.dp))
    }
}

@Composable
fun TriageResultCard(category: TriageCategory, action: String) {
    val (backgroundColor, textColor) = when (category) {
        TriageCategory.RED -> Color.Red to Color.White
        TriageCategory.ORANGE -> Color(0xFFFFA000) to Color.Black
        TriageCategory.YELLOW -> Color.Yellow to Color.Black
        TriageCategory.GREEN -> Color(0xFF00A651) to Color.White
    }

    Card(
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Check, contentDescription = null, tint = textColor)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "CATEGORY: ${category.name}",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = textColor
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = action, style = MaterialTheme.typography.bodyLarge, color = textColor)
        }
    }
}

private fun String.capitalize() = this.replaceFirstChar { it.uppercase() }
