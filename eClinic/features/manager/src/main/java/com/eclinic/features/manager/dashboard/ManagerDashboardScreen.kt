package com.eclinic.features.manager.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
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
import com.eclinic.core.common.model.FacilityStats
import com.eclinic.core.common.model.StatsPeriod
import com.patrykandpatrick.vico.compose.axis.horizontal.rememberBottomAxis
import com.patrykandpatrick.vico.compose.axis.vertical.rememberStartAxis
import com.patrykandpatrick.vico.compose.chart.Chart
import com.patrykandpatrick.vico.compose.chart.column.columnChart
import com.patrykandpatrick.vico.compose.chart.line.lineChart
import com.patrykandpatrick.vico.core.entry.entryModelOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerDashboardScreen(
    viewModel: ManagerViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Facility Manager Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(ManagerIntent.Refresh) }) {
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
                is ManagerState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is ManagerState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(ManagerIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is ManagerState.Success -> {
                    DashboardContent(
                        stats = currentState.stats,
                        selectedPeriod = currentState.selectedPeriod,
                        onPeriodChange = { viewModel.onIntent(ManagerIntent.ChangePeriod(it)) }
                    )
                }
            }
        }
    }
}

@Composable
fun DashboardContent(
    stats: FacilityStats,
    selectedPeriod: StatsPeriod,
    onPeriodChange: (StatsPeriod) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        item {
            PeriodSelector(selectedPeriod, onPeriodChange)
        }

        item {
            SummaryCards(stats)
        }

        item {
            PatientLoadChart(stats)
        }

        item {
            TopDiagnosesSection(stats)
        }
    }
}

@Composable
fun PeriodSelector(selectedPeriod: StatsPeriod, onPeriodChange: (StatsPeriod) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        StatsPeriod.entries.forEach { period ->
            FilterChip(
                selected = selectedPeriod == period,
                onClick = { onPeriodChange(period) },
                label = { Text(period.name) }
            )
        }
    }
}

@Composable
fun SummaryCards(stats: FacilityStats) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            StatCard(
                title = "Total Patients",
                value = stats.totalPatients.toString(),
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.primary
            )
            StatCard(
                title = "Avg Wait Time",
                value = "${stats.averageWaitTimeMinutes}m",
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.secondary
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            StatCard(
                title = "Staff Util.",
                value = "${(stats.staffUtilisationRate * 100).toInt()}%",
                modifier = Modifier.weight(1f),
                color = Color(0xFF00A651)
            )
            StatCard(
                title = "DNA Rate",
                value = "${(stats.dnaRate * 100).toInt()}%",
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.error
            )
        }
    }
}

@Composable
fun StatCard(title: String, value: String, modifier: Modifier = Modifier, color: Color) {
    ElevatedCard(modifier = modifier) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = title, style = MaterialTheme.typography.labelMedium)
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

@Composable
fun PatientLoadChart(stats: FacilityStats) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Patient Load Trend",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(16.dp))
            // Dummy trend data for visualization
            val chartEntryModel = entryModelOf(10, 20, 15, 30, 25, 40, 35)
            Chart(
                chart = lineChart(),
                model = chartEntryModel,
                startAxis = rememberStartAxis(),
                bottomAxis = rememberBottomAxis(),
                modifier = Modifier.height(200.dp)
            )
        }
    }
}

@Composable
fun TopDiagnosesSection(stats: FacilityStats) {
    Column {
        Text(
            text = "Top Diagnoses",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        stats.topDiagnoses.forEach { diagnosis ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = "${diagnosis.icd10Code}: ${diagnosis.description}")
                Text(text = diagnosis.count.toString(), fontWeight = FontWeight.Bold)
            }
            LinearProgressIndicator(
                progress = diagnosis.count.toFloat() / stats.totalPatients,
                modifier = Modifier.fillMaxWidth().height(8.dp),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        }
    }
}
