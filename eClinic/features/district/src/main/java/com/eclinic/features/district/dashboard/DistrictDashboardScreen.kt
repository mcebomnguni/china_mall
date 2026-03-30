package com.eclinic.features.district.dashboard

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
import com.eclinic.core.common.model.*
import com.patrykandpatrick.vico.compose.axis.horizontal.rememberBottomAxis
import com.patrykandpatrick.vico.compose.axis.vertical.rememberStartAxis
import com.patrykandpatrick.vico.compose.chart.Chart
import com.patrykandpatrick.vico.compose.chart.column.columnChart
import com.patrykandpatrick.vico.core.entry.entryModelOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DistrictDashboardScreen(
    viewModel: DistrictDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("District Health Dashboard") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(DistrictDashboardIntent.Refresh) }) {
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
                is DistrictDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is DistrictDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(DistrictDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is DistrictDashboardState.Success -> {
                    DistrictContent(
                        stats = currentState.stats,
                        selectedPeriod = currentState.selectedPeriod,
                        onPeriodChange = { viewModel.onIntent(DistrictDashboardIntent.ChangePeriod(it)) }
                    )
                }
            }
        }
    }
}

@Composable
fun DistrictContent(
    stats: DistrictStats,
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
            DistrictSummaryHeader(stats, selectedPeriod, onPeriodChange)
        }

        item {
            DistrictOverviewCards(stats)
        }

        item {
            FacilityPerformanceList(stats.facilityPerformances)
        }

        item {
            DiseaseBurdenChart(stats.diseaseSurveillance)
        }
    }
}

@Composable
fun DistrictSummaryHeader(
    stats: DistrictStats,
    selectedPeriod: StatsPeriod,
    onPeriodChange: (StatsPeriod) -> Unit
) {
    Column {
        Text(
            text = "District: ${stats.districtName}",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
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
}

@Composable
fun DistrictOverviewCards(stats: DistrictStats) {
    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        StatCard(
            title = "Total Patients",
            value = stats.totalPatients.toString(),
            modifier = Modifier.weight(1f),
            color = MaterialTheme.colorScheme.primary
        )
        StatCard(
            title = "Bed Occupancy",
            value = stats.aggregateBedOccupancy?.let { "${(it * 100).toInt()}%" } ?: "N/A",
            modifier = Modifier.weight(1f),
            color = MaterialTheme.colorScheme.secondary
        )
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
fun FacilityPerformanceList(performances: List<FacilityPerformance>) {
    Column {
        Text(
            text = "Facility Performance",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        performances.forEach { performance ->
            FacilityItem(performance)
        }
    }
}

@Composable
fun FacilityItem(performance: FacilityPerformance) {
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
                Text(performance.facilityName, fontWeight = FontWeight.Bold)
                Text(
                    "Wait: ${performance.averageWaitTime}m | Util: ${(performance.staffUtilization * 100).toInt()}%",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Text(
                text = performance.patientLoad.toString(),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun DiseaseBurdenChart(surveillance: List<DiagnosisFrequency>) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Disease Surveillance (Top ICD-10)",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(16.dp))
            
            if (surveillance.isEmpty()) {
                Text("No data available", modifier = Modifier.padding(vertical = 8.dp))
            } else {
                val chartEntryModel = entryModelOf(*surveillance.map { it.count }.toTypedArray())
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

// Background utility for status boxes
@Composable
fun Modifier.background(color: Color, shape: androidx.compose.ui.graphics.Shape) = this.then(
    androidx.compose.ui.draw.clip(shape).then(androidx.compose.foundation.background(color))
)
