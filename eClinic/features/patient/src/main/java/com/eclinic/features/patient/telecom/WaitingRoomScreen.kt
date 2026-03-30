package com.eclinic.features.patient.telecom

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun WaitingRoomScreen(
    patientId: String,
    onBack: () -> Unit,
    viewModel: WaitingRoomViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        when (val currentState = state) {
            is WaitingRoomState.Initial -> {
                InitialView(onJoin = { viewModel.onIntent(WaitingRoomIntent.JoinWaitingRoom(patientId)) })
            }
            is WaitingRoomState.Loading -> {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
            is WaitingRoomState.Waiting -> {
                WaitingView(currentState.queuePosition)
            }
            is WaitingRoomState.IncomingCall -> {
                IncomingCallView(
                    onAccept = { viewModel.onIntent(WaitingRoomIntent.AcceptCall) },
                    onDecline = { viewModel.onIntent(WaitingRoomIntent.DeclineCall) }
                )
            }
            is WaitingRoomState.InCall -> {
                InCallView(onEndCall = { viewModel.onIntent(WaitingRoomIntent.EndCall) })
            }
            is WaitingRoomState.Error -> {
                Text(text = currentState.message, color = MaterialTheme.colorScheme.error, modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
fun InitialView(onJoin: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(Icons.Default.Videocam, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.primary)
        Spacer(modifier = Modifier.height(24.dp))
        Text("Virtual Consultation", style = MaterialTheme.typography.headlineMedium)
        Text("Join the waiting room to speak with your doctor.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.outline)
        Spacer(modifier = Modifier.height(32.dp))
        Button(onClick = onJoin, modifier = Modifier.fillMaxWidth()) {
            Text("Join Waiting Room")
        }
    }
}

@Composable
fun WaitingView(queuePosition: Int) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator()
        Spacer(modifier = Modifier.height(24.dp))
        Text("You are in the waiting room", style = MaterialTheme.typography.titleLarge)
        Text("Position in queue: $queuePosition", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(8.dp))
        Text("The doctor will be with you shortly.", style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
fun IncomingCallView(onAccept: () -> Unit, onDecline: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Incoming Call", style = MaterialTheme.typography.headlineMedium)
        Text("Dr. Smith is ready for your consultation.", style = MaterialTheme.typography.bodyLarge)
        Spacer(modifier = Modifier.height(48.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(32.dp)) {
            FloatingActionButton(onClick = onDecline, containerColor = Color.Red, contentColor = Color.White) {
                Icon(Icons.Default.CallEnd, contentDescription = "Decline")
            }
            FloatingActionButton(onClick = onAccept, containerColor = Color(0xFF00A651), contentColor = Color.White) {
                Icon(Icons.Default.Call, contentDescription = "Accept")
            }
        }
    }
}

@Composable
fun InCallView(onEndCall: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Video Stream Placeholder
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.Black
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("Video Call in Progress", color = Color.White)
            }
        }
        
        IconButton(
            onClick = onEndCall,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp)
                .size(64.dp),
            colors = IconButtonDefaults.iconButtonColors(containerColor = Color.Red, contentColor = Color.White)
        ) {
            Icon(Icons.Default.CallEnd, contentDescription = "End Call")
        }
    }
}
