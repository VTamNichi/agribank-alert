package com.agribankalert.agribank_alert

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.agribankalert/notification_listener"
    private val EVENT_CHANNEL = "com.agribankalert/notification_stream"
    private val TEST_CHANNEL_ID = "agribank_test_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerPermissionGranted" -> {
                    result.success(isNotificationListenerPermissionGranted())
                }
                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    try {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getPendingNotifications" -> {
                    val list = NotificationReceiverBridge.getPendingNotifications(applicationContext)
                    result.success(list)
                }
                "clearPendingNotifications" -> {
                    NotificationReceiverBridge.clearPendingNotifications(applicationContext)
                    result.success(true)
                }
                "getMonitoredPackages" -> {
                    val list = NotificationReceiverBridge.getMonitoredPackages(applicationContext).toList()
                    result.success(list)
                }
                "setMonitoredPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    NotificationReceiverBridge.setMonitoredPackages(applicationContext, packages)
                    result.success(true)
                }
                "sendTestNotification" -> {
                    val title = call.argument<String>("title") ?: "Agribank Alert"
                    val content = call.argument<String>("content") ?: "Biến động số dư TK 1500205123456: +500,000 VND"
                    val success = postTestNotification(title, content)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationReceiverBridge.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    NotificationReceiverBridge.setEventSink(null)
                }
            }
        )
    }

    private fun isNotificationListenerPermissionGranted(): Boolean {
        val cn = ComponentName(this, AgribankNotificationListenerService::class.java)
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(cn.flattenToString())
    }

    private fun postTestNotification(title: String, content: String): Boolean {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    TEST_CHANNEL_ID,
                    "Agribank Test Notifications",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Channel for testing Agribank transaction alerts"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val builder = NotificationCompat.Builder(this, TEST_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(content)
                .setStyle(NotificationCompat.BigTextStyle().bigText(content))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

            val notifId = (System.currentTimeMillis() % 10000).toInt()
            notificationManager.notify(notifId, builder.build())
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
