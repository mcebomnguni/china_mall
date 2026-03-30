package com.eclinic.features.national.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.eclinic.core.common.model.*
import com.patrykandpatrick.vico.compose.axis.horizontal.rememberBottomAxis
import com.patrykandpatrick.vico.compose.axis.vertical.rememberStartAxis
import com.patrykandpatrick.vico.compose.chart.Chart
import com.patrykandpatrick.vico.compose.chart.column.columnChart
import com.patrykandpatrick.vico.core.entry.entryModelOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NationalDashboardScreen(
    viewModel: NationalDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("National Health Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(NationalDashboardIntent.Refresh) }) {
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
                is NationalDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is NationalDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(NationalDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is NationalDashboardState.Success -> {
                    NationalContent(
                        stats = currentState.stats,
                        selectedPeriod = currentState.selectedPeriod,
                        onPeriodChange = { viewModel.onIntent(NationalDashboardIntent.ChangePeriod(it)) }
                    )
                }
            }
        }
    }
}

@Composable
fun NationalContent(
    stats: NationalStats,
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
            NationalSummaryHeader(selectedPeriod, onPeriodChange)
        }

        item {
            NationalKPIOverview(stats)
        }

        item {
            ProvinceComparisonList(stats.provincePerformances)
        }

        item {
            NationalDiseaseBurdenChart(stats.nationalDiseaseBurden)
        }
    }
}

@Composable
fun NationalSummaryHeader(
    selectedPeriod: StatsPeriod,
    onPeriodChange: (StatsPeriod) -> Unit
) {
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
fun NationalKPIOverview(stats: NationalStats) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            StatCard(
                title = "Total Patients (Nat.)",
                value = stats.totalPatientsNationwide.toString(),
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.primary
            )
            StatCard(
                title = "Immunization Cov.",
                value = "${(stats.nationalImmunizationCoverage * 100).toInt()}%",
                modifier = Modifier.weight(1f),
                color = Color(0xFF00A651)
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            StatCard(
                title = "Avg Bed Occupancy",
                value = "${(stats.nationalBedOccupancyRate * 100).toInt()}%",
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.secondary
            )
            StatCard(
                title = "Nat. Workforce",
                value = stats.healthcareWorkforceNationwide.toString(),
                modifier = Modifier.weight(1f),
                color = Color(0xFF1976D2)
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
fun ProvinceComparisonList(performances: List<ProvincePerformance>) {
    Column {
        Text(
            text = "Provincial Health Readiness",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        performances.forEach { performance ->
            ProvinceItem(performance)
        }
    }
}

@Composable
fun ProvinceItem(performance: ProvincePerformance) {
    val statusColor = when (performance.status) {
        HealthStatus.NORMAL -> Color(0xFF00A651)
        HealthStatus.UNDER_PRESSURE -> Color(0xFFFFA000)
        HealthStatus.CRITICAL -> Color(0xFFD32F2F)
    }

    OutlinedCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(statusColor, MaterialTheme.shapes.small)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(performance.provinceName, fontWeight = FontWeight.Bold)
                Text(
                    "Readiness Index: ${(performance.healthReadinessIndex * 100).toInt()}%",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Text(
                text = performance.totalPatients.toString(),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun NationalDiseaseBurdenChart(burden: List<DiagnosisFrequency>) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "National Disease Burden Aggregate",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(16.dp))
            if (burden.isEmpty()) {
                Text("No data available", modifier = Modifier.padding(vertical = 8.dp))
            } else {
                val chartEntryModel = entryModelOf(*burden.map { it.count }.toTypedArray())
                Chart(
                    chart = columnChart(),
                    model = chartEntryModel,
                    startAxis = rememberStartAxis(),
                    bottomAxis = rememberBottomAxis(),
                    modifier = Modifier.height(200.dp)
                )
            }
        }
    }
}

@Composable
fun Modifier.background(color: Color, shape: androidx.compose.ui.graphics.Shape) = this.then(
    androidx.compose.ui.draw.clip(shape).then(androidx.compose.foundation.background(color))
)
