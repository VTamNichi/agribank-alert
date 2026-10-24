import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../models/transaction_alert.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'agribank_alert_credit_channel';
  static const String channelName = 'Agribank Alert - Tiền Vào';
  static const String channelDescription = 'Thông báo nổi khi có giao dịch nhận tiền từ tài khoản Agribank';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Tạo Notification Channel ưu tiên cao
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo LocalNotificationService: $e');
    }
  }

  Future<void> showTransactionNotification(TransactionAlert alert) async {
    if (!_isInitialized) await init();

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final formattedAmount = '${currencyFormat.format(alert.amount)} ${alert.currency}';

    final title = 'Agribank Alert — Nhận tiền';
    final content = 'Bạn vừa nhận +$formattedAmount';
    final bigText = [
      content,
      if (alert.accountNumber != null) 'Tài khoản: ${alert.accountNumber}',
      if (alert.senderName != null) 'Nội dung: ${alert.senderName}',
      if (alert.referenceCode != null) 'Mã GD: ${alert.referenceCode}',
    ].join('\n');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Agribank Alert: Nhận +$formattedAmount',
      styleInformation: BigTextStyleInformation(bigText),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final notifId = alert.eventId.hashCode & 0x7FFFFFFF;
    await _notificationsPlugin.show(
      id: notifId,
      title: title,
      body: content,
      notificationDetails: notificationDetails,
      payload: alert.toJson(),
    );
  }
}
