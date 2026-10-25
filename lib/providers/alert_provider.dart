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
  bool _isServerConnected = false;
  String? _lastLog;

  List<TransactionAlert> get history => _history;
  TransactionAlert? get latestAlert => _latestAlert;
  bool get isListening => _isListening;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isBatteryOptIgnored => _isBatteryOptIgnored;
  bool get isServerConnected => _isServerConnected;
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

    // Khởi động lắng nghe thông báo Android (Máy A hoặc Standalone)
    startListening();

    // Quét các thông báo chưa đọc trong hàng đợi nền
    await drainPendingNotifications();

    // Nếu là Máy B (Receiver): kết nối WebSocket đến server để nhận thông báo từ xa
    final role = _storage.getDeviceRole();
    if (role == DeviceRole.receiver) {
      _connectToRelayServer();
    }

    notifyListeners();
  }

  void reconnectRelayServer() {
    final role = _storage.getDeviceRole();
    if (role == DeviceRole.receiver) {
      _connectToRelayServer();
    } else {
      _relay.disconnectWebSocket();
      _isServerConnected = false;
      notifyListeners();
    }
  }

  void _connectToRelayServer() {
    final pairingInfo = _storage.getPairingInfo();
    final serverUrl = pairingInfo.serverUrl;
    final deviceId = _storage.getDeviceId();
    final deviceName = _storage.getDeviceName();

    if (serverUrl != null && serverUrl.isNotEmpty) {
      _relay.onAlertReceived = (alert) {
        _history = _storage.getHistory();
        _latestAlert = alert;
        _lastLog = '💰 Nhận từ xa: +${alert.amount.toInt()} VND';
        notifyListeners();
      };

      _relay.onConnectionChanged = (connected) {
        _isServerConnected = connected;
        _lastLog = connected
            ? '✅ Đã kết nối server chuyển tiếp'
            : '⚠️ Mất kết nối server. Đang kết nối lại...';
        notifyListeners();
      };

      _relay.connectWebSocket(
        serverUrl: serverUrl,
        deviceId: deviceId,
        deviceName: deviceName,
      );
    }
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

    // 2. Lọc số tiền tối đa (mặc định: chỉ bắn dưới 10 triệu)
    if (_storage.getMaxAmountFilterEnabled()) {
      final maxLimit = _storage.getMaxAmountLimit();
      if (alert.amount >= maxLimit) {
        _lastLog = '⛔ Bỏ qua: +${alert.amount.toInt()} VND vượt ngưỡng ${maxLimit.toInt()} VND';
        notifyListeners();
        return;
      }
    }

    // 3. Chống trùng lặp (Duplicate Check)
    final isDuplicate = await _storage.isEventProcessed(alert.eventId);
    if (isDuplicate) {
      _lastLog = 'Phát hiện thông báo trùng (Event ID: ${alert.eventId}) -> Bỏ qua';
      notifyListeners();
      return;
    }

    // 4. Đánh dấu đã xử lý & lưu lịch sử
    await _storage.markEventProcessed(alert.eventId);
    await _storage.addTransactionToHistory(alert);
    _history = _storage.getHistory();
    _latestAlert = alert;

    final role = _storage.getDeviceRole();
    final pairingInfo = _storage.getPairingInfo();

    _lastLog = '✅ Xử lý giao dịch nhận +${alert.amount.toInt()} VND';

    // 5. Nếu là Máy B (Receiver) hoặc Máy Test (Standalone): Phát thông báo nổi & Đọc giọng nói
    if (role == DeviceRole.receiver || role == DeviceRole.standalone) {
      await _localNotifications.showTransactionNotification(alert);
      final prefix = _storage.getTtsPrefix();
      await _tts.speakTransaction(alert, prefix: prefix);
    }

    // 6. Nếu là Máy A (Sender): Chuyển tiếp sự kiện sang Server
    if (role == DeviceRole.sender) {
      final relayResult = await _relay.forwardTransactionAlert(
        alert: alert,
        senderDeviceId: pairingInfo.deviceId,
        targetDeviceId: pairingInfo.pairedDeviceId,
        serverUrl: pairingInfo.serverUrl,
      );
      _lastLog = 'Chuyển tiếp: ${relayResult.message}';
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

  @override
  void dispose() {
    _relay.disconnectWebSocket();
    super.dispose();
  }
}
