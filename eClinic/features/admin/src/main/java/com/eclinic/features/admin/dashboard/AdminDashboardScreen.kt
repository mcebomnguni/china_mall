package com.eclinic.features.admin.dashboard

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
import com.eclinic.core.common.model.InventoryItem
import com.eclinic.core.common.model.StaffMember
import com.eclinic.core.common.model.UserRole

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminDashboardScreen(
    viewModel: AdminDashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Facility Administration") },
                actions = {
                    IconButton(onClick = { viewModel.onIntent(AdminDashboardIntent.Refresh) }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        },
        bottomBar = {
            if (state is AdminDashboardState.Success) {
                AdminBottomNavigation(
                    activeTab = (state as AdminDashboardState.Success).activeTab,
                    onTabSelected = { viewModel.onIntent(AdminDashboardIntent.ChangeTab(it)) }
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (val currentState = state) {
                is AdminDashboardState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is AdminDashboardState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = currentState.message, color = MaterialTheme.colorScheme.error)
                        Button(onClick = { viewModel.onIntent(AdminDashboardIntent.Refresh) }) {
                            Text("Retry")
                        }
                    }
                }
                is AdminDashboardState.Success -> {
                    when (currentState.activeTab) {
                        AdminTab.STAFF -> StaffList(currentState.staff)
                        AdminTab.INVENTORY -> InventoryList(currentState.inventory)
                        AdminTab.CONFIG -> ConfigPlaceholder()
                    }
                }
            }
        }
    }
}

@Composable
fun AdminBottomNavigation(activeTab: AdminTab, onTabSelected: (AdminTab) -> Unit) {
    NavigationBar {
        NavigationBarItem(
            selected = activeTab == AdminTab.STAFF,
            onClick = { onTabSelected(AdminTab.STAFF) },
            icon = { Icon(Icons.Default.People, contentDescription = null) },
            label = { Text("Staff") }
        )
        NavigationBarItem(
            selected = activeTab == AdminTab.INVENTORY,
            onClick = { onTabSelected(AdminTab.INVENTORY) },
            icon = { Icon(Icons.Default.Inventory, contentDescription = null) },
            label = { Text("Inventory") }
        )
        NavigationBarItem(
            selected = activeTab == AdminTab.CONFIG,
            onClick = { onTabSelected(AdminTab.CONFIG) },
            icon = { Icon(Icons.Default.Settings, contentDescription = null) },
            label = { Text("Config") }
        )
    }
}

@Composable
fun StaffList(staff: List<StaffMember>) {
    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            Text("Facility Staff Members", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
        items(staff) { member ->
            ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("${member.firstName} ${member.lastName}", style = MaterialTheme.typography.titleMedium)
                        Text(member.role.name, style = MaterialTheme.typography.bodySmall)
                    }
                    StatusBadge(member.isActive)
                }
            }
        }
    }
}

@Composable
fun StatusBadge(isActive: Boolean) {
    val color = if (isActive) Color(0xFF00A651) else Color.Red
    Surface(color = color, shape = MaterialTheme.shapes.small) {
        Text(
            text = if (isActive) "ACTIVE" else "INACTIVE",
            color = Color.White,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelSmall
        )
    }
}

@Composable
fun InventoryList(inventory: List<InventoryItem>) {
    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Medical Inventory", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
        items(inventory) { item ->
            OutlinedCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(item.name, style = MaterialTheme.typography.titleMedium)
                        Text(item.category, style = MaterialTheme.typography.labelMedium)
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            text = item.stockLevel.toString(),
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = if (item.stockLevel <= item.minStockLevel) Color.Red else Color.Unspecified
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(item.unit, style = MaterialTheme.typography.bodySmall)
                    }
                    if (item.stockLevel <= item.minStockLevel) {
                        Text("LOW STOCK ALERT", color = Color.Red, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
fun ConfigPlaceholder() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("Facility Configuration Module")
    }
}
