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
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString() ?: ""

        val combined = "$packageName $title $text $bigText $subText".lowercase()
        val isAgribankRelated = combined.contains("agribank") || combined.contains("vnpay") || combined.contains("1500")

        val isSmsApp = packageName.contains("messaging") || 
                       packageName.contains("mms") || 
                       packageName.contains("telephony") ||
                       packageName.contains("sms") ||
                       packageName == "com.google.android.apps.messaging" ||
                       packageName == "com.samsung.android.messaging" ||
                       packageName == "com.android.mms"

        val monitored = NotificationReceiverBridge.getMonitoredPackages(applicationContext)

        // Cho phép thông báo nếu:
        // 1. Gói ứng dụng nằm trong danh sách theo dõi
        // 2. Chế độ debug bắt tất cả (*)
        // 3. Ứng dụng SMS có chứa nội dung liên quan Agribank
        // 4. Bất kỳ thông báo nào liên quan Agribank có dấu hiệu biến động số dư (+ hoặc nhận tiền)
        val isMonitored = monitored.contains(packageName) || 
                          monitored.contains("*") || 
                          (isSmsApp && isAgribankRelated) ||
                          (isAgribankRelated && (combined.contains("+") || combined.contains("nhan tien") || combined.contains("so du")))

        if (!isMonitored) {
            return
        }

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
