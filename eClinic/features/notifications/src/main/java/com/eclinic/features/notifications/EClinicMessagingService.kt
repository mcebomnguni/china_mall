package com.eclinic.features.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class EClinicMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var notificationHandler: EClinicNotificationHandler

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        
        val title = message.notification?.title ?: message.data["title"] ?: "eClinic Alert"
        val body = message.notification?.body ?: message.data["body"] ?: ""
        val type = message.data["type"] ?: "GENERAL"

        notificationHandler.showNotification(title, body, type)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // In a real app, send this token to the backend to associate with the user
    }
}

class EClinicNotificationHandler @Inject constructor(
    private val context: Context
) {
    private val notificationManager = 
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun showNotification(title: String, body: String, type: String) {
        val channelId = when (type) {
            "PANIC" -> "critical_alerts"
            "APPOINTMENT" -> "reminders"
            else -> "general_notifications"
        }

        createNotificationChannel(channelId)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Placeholder icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(if (type == "PANIC") NotificationCompat.PRIORITY_MAX else NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel(channelId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_31) {
            val name = when (channelId) {
                "critical_alerts" -> "Critical Clinical Alerts"
                "reminders" -> "Patient Reminders"
                else -> "General Notifications"
            }
            val importance = if (channelId == "critical_alerts") {
                NotificationManager.IMPORTANCE_HIGH
            } else {
                NotificationManager.IMPORTANCE_DEFAULT
            }
            val channel = NotificationChannel(channelId, name, importance)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
