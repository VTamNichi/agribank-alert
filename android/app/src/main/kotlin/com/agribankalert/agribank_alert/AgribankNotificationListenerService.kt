package com.agribankalert.agribank_alert

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class AgribankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "AgribankNotifListener"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "AgribankNotificationListenerService connected successfully")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        val monitored = NotificationReceiverBridge.getMonitoredPackages(applicationContext)

        // If package is not monitored and not in test mode, ignore
        val isMonitored = monitored.contains(packageName) || monitored.contains("*")
        if (!isMonitored) {
            return
        }

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString() ?: ""

        val postTime = sbn.postTime
        val notificationId = sbn.id
        val key = sbn.key ?: ""

        Log.d(TAG, "Captured notification from $packageName: Title='$title', Text='$text'")

        val dataMap = mapOf(
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "bigText" to bigText,
            "subText" to subText,
            "infoText" to infoText,
            "postTime" to postTime,
            "notificationId" to notificationId,
            "key" to key
        )

        NotificationReceiverBridge.onNotificationPosted(applicationContext, dataMap)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
