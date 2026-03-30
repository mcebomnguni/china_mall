package com.eclinic.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.eclinic.features.auth.login.LoginScreen
import com.eclinic.features.doctor.dashboard.DoctorDashboardScreen

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object DoctorDashboard : Screen("doctor_dashboard")
}

@Composable
fun NavGraph(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Screen.Login.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.DoctorDashboard.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }
        composable(Screen.DoctorDashboard.route) {
            DoctorDashboardScreen(
                onPatientClick = { patientId ->
                    // Navigate to Patient Details when implemented
                }
            )
        }
    }
}
