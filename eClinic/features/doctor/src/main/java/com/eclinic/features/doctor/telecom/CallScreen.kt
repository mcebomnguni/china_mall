package com.eclinic.features.doctor.telecom

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
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

@Composable
fun CallScreen(
    patientId: String,
    onBack: () -> Unit,
    viewModel: CallViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(patientId) {
        viewModel.onIntent(CallIntent.InitCall(patientId))
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        when (val currentState = state) {
            is CallState.Loading -> {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center), color = Color.White)
            }
            is CallState.Ready -> {
                ReadyToCallView(
                    onStart = { viewModel.onIntent(CallIntent.StartCall) },
                    onCancel = onBack
                )
            }
            CallState.Calling -> {
                CallingView()
            }
            CallState.Connected -> {
                ConnectedCallView(
                    onEnd = { 
                        viewModel.onIntent(CallIntent.EndCall)
                        onBack()
                    }
                )
            }
            is CallState.Error -> {
                Text(text = currentState.message, color = Color.Red, modifier = Modifier.align(Alignment.Center))
            }
            else -> {}
        }
    }
}

@Composable
fun ReadyToCallView(onStart: () -> Unit, onCancel: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Ready to start consultation?", color = Color.White, style = MaterialTheme.typography.headlineSmall)
        Spacer(modifier = Modifier.height(32.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Button(onClick = onCancel, colors = ButtonDefaults.buttonColors(containerColor = Color.DarkGray)) {
                Text("Cancel")
            }
            Button(onClick = onStart, colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00A651))) {
                Text("Start Call")
            }
        }
    }
}

@Composable
fun CallingView() {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator(color = Color.White)
        Spacer(modifier = Modifier.height(24.dp))
        Text("Establishing secure connection...", color = Color.White)
    }
}

@Composable
fun ConnectedCallView(onEnd: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Patient Video Surface Placeholder
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text("Remote Patient Video", color = Color.Gray)
        }

        // Doctor Self Preview Placeholder
        Surface(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp)
                .size(width = 120.dp, height = 160.dp),
            color = Color.DarkGray,
            shape = MaterialTheme.shapes.medium
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("Self", color = Color.LightGray, style = MaterialTheme.typography.labelSmall)
            }
        }

        // Call Controls
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(24.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            FloatingActionButton(
                onClick = { },
                containerColor = Color.DarkGray,
                contentColor = Color.White
            ) {
                Icon(Icons.Default.Mic, contentDescription = "Mute")
            }
            
            FloatingActionButton(
                onClick = onEnd,
                containerColor = Color.Red,
                contentColor = Color.White,
                modifier = Modifier.size(72.dp)
            ) {
                Icon(Icons.Default.CallEnd, contentDescription = "End Call", modifier = Modifier.size(32.dp))
            }

            FloatingActionButton(
                onClick = { },
                containerColor = Color.DarkGray,
                contentColor = Color.White
            ) {
                Icon(Icons.Default.Videocam, contentDescription = "Video")
            }
        }
    }
}
