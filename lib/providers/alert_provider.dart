import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/device_role.dart';
import '../core/models/transaction_alert.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/notification_listener_service.dart';
import '../core/services/notification_parser.dart';
import '../core/services/relay_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/tts_service.dart';

class AlertProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NativeNotificationListenerService _nativeListener = NativeNotificationListenerService();
  final TtsService _tts = TtsService();
  final LocalNotificationService _localNotifications = LocalNotificationService();
  final RelayService _relay = RelayService();

  List<TransactionAlert> _history = [];
  TransactionAlert? _latestAlert;
  bool _isListening = false;
  bool _hasNotificationPermission = false;
  bool _isBatteryOptIgnored = false;
  String? _lastLog;

  List<TransactionAlert> get history => _history;
  TransactionAlert? get latestAlert => _latestAlert;
  bool get isListening => _isListening;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isBatteryOptIgnored => _isBatteryOptIgnored;
  String? get lastLog => _lastLog;

  double get totalReceivedToday {
    final now = DateTime.now();
    return _history
        .where((a) =>
            a.isCredit &&
            a.occurredAt.year == now.year &&
            a.occurredAt.month == now.month &&
            a.occurredAt.day == now.day)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  int get transactionCountToday {
    final now = DateTime.now();
    return _history
        .where((a) =>
            a.isCredit &&
            a.occurredAt.year == now.year &&
            a.occurredAt.month == now.month &&
            a.occurredAt.day == now.day)
        .length;
  }

  Future<void> init() async {
    await _storage.init();
    await _tts.init();
    await _localNotifications.init();

    _history = _storage.getHistory();
    _tts.updateSettings(
      isEnabled: _storage.getTtsEnabled(),
      volume: _storage.getTtsVolume(),
      rate: _storage.getTtsRate(),
    );

    await checkPermissions();

    // Khởi động lắng nghe thông báo Android
    startListening();

    // Quét các thông báo chưa đọc trong hàng đợi nền
    await drainPendingNotifications();

    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _hasNotificationPermission = await _nativeListener.isPermissionGranted();
    _isBatteryOptIgnored = await _nativeListener.isBatteryOptimizationIgnored();
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    await _nativeListener.openSettings();
    await Future.delayed(const Duration(seconds: 1));
    await checkPermissions();
  }

  Future<void> requestBatteryOptimization() async {
    await _nativeListener.requestIgnoreBatteryOptimization();
    await Future.delayed(const Duration(seconds: 1));
    await checkPermissions();
  }

  void startListening() {
    if (_isListening) return;

    _nativeListener.startListening((data) {
      handleRawNotification(data);
    });
    _isListening = true;
    _lastLog = 'Đang lắng nghe thông báo Agribank...';
    notifyListeners();
  }

  void stopListening() {
    _nativeListener.stopListening();
    _isListening = false;
    _lastLog = 'Đã tạm dừng lắng nghe';
    notifyListeners();
  }

  Future<void> drainPendingNotifications() async {
    final pending = await _nativeListener.getPendingNotifications();
    if (pending.isNotEmpty) {
      _lastLog = 'Phát hiện ${pending.length} thông báo trong hàng đợi nền';
      for (final data in pending) {
        await handleRawNotification(data);
      }
      await _nativeListener.clearPendingNotifications();
    }
  }

  Future<void> handleRawNotification(Map<String, dynamic> data) async {
    final rawTitle = data['title']?.toString() ?? '';
    final rawText = data['text']?.toString() ?? '';
    final bigText = data['bigText']?.toString();
    final subText = data['subText']?.toString();
    final deviceId = _storage.getDeviceId();

    _lastLog = 'Nhận thông báo: "$rawTitle" - "$rawText"';
    notifyListeners();

    // 1. Phân tích nội dung qua bộ Parser
    final parseResult = NotificationParser.parse(
      rawTitle: rawTitle,
      rawContent: rawText,
      bigText: bigText,
      subText: subText,
      deviceId: deviceId,
    );

    if (!parseResult.isValidTransaction || !parseResult.isCredit || parseResult.alert == null) {
      _lastLog = 'Bỏ qua: ${parseResult.rejectReason ?? 'Không phải giao dịch tiền vào'}';
      notifyListeners();
      return;
    }

    final alert = parseResult.alert!;

    // 2. Chống trùng lặp (Duplicate Check)
    final isDuplicate = await _storage.isEventProcessed(alert.eventId);
    if (isDuplicate) {
      _lastLog = 'Phát hiện thông báo trùng (Event ID: ${alert.eventId}) -> Bỏ qua';
      notifyListeners();
      return;
    }

    // 3. Đánh dấu đã xử lý & lưu lịch sử
    await _storage.markEventProcessed(alert.eventId);
    await _storage.addTransactionToHistory(alert);
    _history = _storage.getHistory();
    _latestAlert = alert;

    final role = _storage.getDeviceRole();
    final pairingInfo = _storage.getPairingInfo();

    _lastLog = 'Xử lý thành công giao dịch nhận +${alert.amount} VND';

    // 4. Nếu là Máy B (Receiver) hoặc Máy Test (Standalone): Phát thông báo nổi & Đọc giọng nói
    if (role == DeviceRole.receiver || role == DeviceRole.standalone) {
      await _localNotifications.showTransactionNotification(alert);
      final prefix = _storage.getTtsPrefix();
      await _tts.speakTransaction(alert, prefix: prefix);
    }

    // 5. Nếu là Máy A (Sender): Chuyển tiếp sự kiện sang Máy B qua Relay/Firebase
    if (role == DeviceRole.sender) {
      final relayResult = await _relay.forwardTransactionAlert(
        alert: alert,
        pairingInfo: pairingInfo,
      );
      _lastLog = 'Chuyển tiếp đến Máy B: ${relayResult.message}';
    }

    notifyListeners();
  }

  /// Giả lập nhận một giao dịch để kiểm thử tức thì
  Future<void> simulateNotification(String title, String content) async {
    await handleRawNotification({
      'title': title,
      'text': content,
      'packageName': 'com.vnpay.Agribank3g',
      'postTime': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Đọc lại một thông báo trong lịch sử
  Future<void> replayAlertVoice(TransactionAlert alert) async {
    final prefix = _storage.getTtsPrefix();
    await _tts.speakTransaction(alert, prefix: prefix);
  }

  Future<void> clearHistory() async {
    await _storage.clearHistory();
    _history = [];
    _latestAlert = null;
    notifyListeners();
  }
}
