import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_alert.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';
import 'tts_service.dart';

// Background handler bắt buộc phải là top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final data = message.data;
    if (data.isNotEmpty) {
      final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
      final alert = TransactionAlert(
        eventId: data['eventId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: data['deviceId']?.toString() ?? 'remote-device',
        amount: amount,
        currency: data['currency']?.toString() ?? 'VND',
        direction: data['direction']?.toString() ?? 'credit',
        occurredAt: DateTime.tryParse(data['occurredAt']?.toString() ?? '') ?? DateTime.now(),
        accountNumber: data['accountNumber']?.toString(),
        senderName: data['senderName']?.toString(),
        referenceCode: data['referenceCode']?.toString(),
        rawTitle: data['rawTitle']?.toString() ?? 'Agribank Alert',
        rawContent: data['rawContent']?.toString() ?? '',
      );

      // Kiểm tra trùng lặp
      final storage = StorageService();
      await storage.init();
      if (!await storage.isEventProcessed(alert.eventId)) {
        await storage.markEventProcessed(alert.eventId);
        await storage.addTransactionToHistory(alert);

        // Hiển thị thông báo nổi
        final localNotif = LocalNotificationService();
        await localNotif.init();
        await localNotif.showTransactionNotification(alert);

        // Đọc âm thanh nếu bật
        if (storage.getTtsEnabled()) {
          final tts = TtsService();
          await tts.init();
          final prefix = storage.getTtsPrefix();
          await tts.speakTransaction(alert, prefix: prefix);
        }
      }
    }
  } catch (e) {
    debugPrint('Lỗi xử lý FCM Background: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Token của thiết bị B: $_fcmToken');

        // Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          debugPrint('Nhận thông báo FCM Foreground: ${message.data}');
          final data = message.data;
          if (data.isNotEmpty) {
            final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
            final alert = TransactionAlert(
              eventId: data['eventId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              deviceId: data['deviceId']?.toString() ?? 'remote-device',
              amount: amount,
              currency: data['currency']?.toString() ?? 'VND',
              direction: data['direction']?.toString() ?? 'credit',
              occurredAt: DateTime.tryParse(data['occurredAt']?.toString() ?? '') ?? DateTime.now(),
              accountNumber: data['accountNumber']?.toString(),
              senderName: data['senderName']?.toString(),
              referenceCode: data['referenceCode']?.toString(),
              rawTitle: data['rawTitle']?.toString() ?? 'Agribank Alert',
              rawContent: data['rawContent']?.toString() ?? '',
            );

            final storage = StorageService();
            await storage.init();
            if (!await storage.isEventProcessed(alert.eventId)) {
              await storage.markEventProcessed(alert.eventId);
              await storage.addTransactionToHistory(alert);

              await LocalNotificationService().showTransactionNotification(alert);
              if (storage.getTtsEnabled()) {
                final prefix = storage.getTtsPrefix();
                await TtsService().speakTransaction(alert, prefix: prefix);
              }
            }
          }
        });

        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Chưa khởi tạo được Firebase (Cần file google-services.json): $e');
      return false;
    }
  }
}
