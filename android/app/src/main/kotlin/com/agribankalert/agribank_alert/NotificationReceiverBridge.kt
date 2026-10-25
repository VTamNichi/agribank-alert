package com.agribankalert.agribank_alert

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

object NotificationReceiverBridge {
    private const val PREFS_NAME = "agribank_alert_prefs"
    private const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"
    private const val KEY_MONITORED_PACKAGES = "monitored_packages"
    private const val MAX_PENDING = 100

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun onNotificationPosted(context: Context, data: Map<String, Any?>) {
        // Dispatch to Flutter if active
        mainHandler.post {
            try {
                eventSink?.success(data)
            } catch (e: Exception) {
                // If stream is closed or fails, save to pending
                savePendingNotification(context, data)
            }
        }

        // Always save to pending buffer if Flutter eventSink is not attached yet
        if (eventSink == null) {
            savePendingNotification(context, data)
        }
    }

    private fun savePendingNotification(context: Context, data: Map<String, Any?>) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentList = getPendingNotifications(context).toMutableList()
            currentList.add(data)

            // Keep only latest MAX_PENDING
            val trimmedList = if (currentList.size > MAX_PENDING) {
                currentList.takeLast(MAX_PENDING)
            } else {
                currentList
            }

            val jsonArray = JSONArray()
            for (item in trimmedList) {
                jsonArray.put(JSONObject(item))
            }

            prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, jsonArray.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getPendingNotifications(context: Context): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_PENDING_NOTIFICATIONS, null) ?: return list
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val map = mutableMapOf<String, Any?>()
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    map[key] = obj.get(key)
                }
                list.add(map)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }

    fun clearPendingNotifications(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_PENDING_NOTIFICATIONS).apply()
    }

    fun getMonitoredPackages(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val defaultSet = setOf(
            "com.vnpay.Agribank3g",
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.agribankalert.agribank_alert"
        )
        return prefs.getStringSet(KEY_MONITORED_PACKAGES, defaultSet) ?: defaultSet
    }

    fun setMonitoredPackages(context: Context, packages: List<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_MONITORED_PACKAGES, packages.toSet()).apply()
    }
}
