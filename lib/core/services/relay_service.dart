import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/transaction_alert.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';
import 'tts_service.dart';

class RelayResult {
  final bool success;
  final String message;
  final dynamic data;
  final int? latencyMs;

  RelayResult({
    required this.success,
    required this.message,
    this.data,
    this.latencyMs,
  });
}

class RelayService {
  static final RelayService _instance = RelayService._internal();
  factory RelayService() => _instance;
  RelayService._internal();

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _currentServerUrl;
  String? _currentDeviceId;
  String? _currentDeviceName;

  // Callback khi nhận được giao dịch từ máy A
  Function(TransactionAlert alert)? onAlertReceived;
  Function(bool connected)? onConnectionChanged;
  Function(String pairedDeviceId, String pairedDeviceName)? onPairingUpdated;

  bool get isConnected => _isConnected;

  /// Chuẩn hóa URL máy chủ
  static String normalizeUrl(String? raw) {
    if (raw == null) return '';
    var url = raw.trim();
    if (url.isEmpty) return '';

    // Loại bỏ dấu gạch chéo cuối
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Nếu là localhost hoặc ip mạng LAN thì dùng http, còn lại dùng https
      if (url.contains('localhost') ||
          url.startsWith('192.168.') ||
          url.startsWith('10.') ||
          url.startsWith('127.0.0.1')) {
        url = 'http://$url';
      } else {
        url = 'https://$url';
      }
    }

    return url;
  }

  /// Kiểm tra trạng thái kết nối máy chủ
  Future<RelayResult> testServerConnection(String? rawUrl) async {
    final url = normalizeUrl(rawUrl);
    if (url.isEmpty) {
      return RelayResult(
        success: false,
        message: 'Vui lòng nhập địa chỉ URL máy chủ',
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final endpoint = '$url/health';
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 45));
      stopwatch.stop();

      if (response.statusCode == 200) {
        return RelayResult(
          success: true,
          message: 'Kết nối máy chủ thành công (${stopwatch.elapsedMilliseconds}ms)',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return RelayResult(
          success: false,
          message: 'Máy chủ phản hồi mã lỗi HTTP ${response.statusCode}',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
    } on TimeoutException {
      return RelayResult(
        success: false,
        message: 'Máy chủ Render đang khởi động (cold-start mất ~30-50s). Vui lòng thử lại sau 20 giây!',
      );
    } catch (e) {
      return RelayResult(
        success: false,
        message: 'Không thể kết nối đến máy chủ: $e',
      );
    }
  }

  /// Kết nối WebSocket tới server chuyển tiếp (cho Điện thoại B)
  void connectWebSocket({
    required String serverUrl,
    required String deviceId,
    String? deviceName,
  }) {
    _currentServerUrl = normalizeUrl(serverUrl);
    _currentDeviceId = deviceId;
    _currentDeviceName = deviceName;

    _doConnect();
  }

  void _doConnect() {
    if (_currentServerUrl == null || _currentServerUrl!.isEmpty || _currentDeviceId == null) return;

    // Đóng kết nối cũ nếu có
    disconnectWebSocket();

    try {
      // Chuyển HTTP URL thành WS URL
      String wsUrl = _currentServerUrl!;
      if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      } else if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceFirst('http://', 'ws://');
      } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        wsUrl = 'wss://$wsUrl';
      }

      debugPrint('[WS] Đang kết nối đến: $wsUrl');

      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsSubscription = _wsChannel!.stream.listen(
        (dynamic message) {
          _handleWsMessage(message.toString());
        },
        onDone: () {
          debugPrint('[WS] Kết nối đã đóng. Thử kết nối lại sau 5 giây...');
          _isConnected = false;
          onConnectionChanged?.call(false);
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('[WS] Lỗi WebSocket: $error');
          _isConnected = false;
          onConnectionChanged?.call(false);
          _scheduleReconnect();
        },
      );

      // Gửi lệnh đăng ký thiết bị
      _sendWs({
        'type': 'register',
        'deviceId': _currentDeviceId,
        'deviceName': _currentDeviceName ?? 'Thiết bị Agribank B',
      });

      _isConnected = true;
      onConnectionChanged?.call(true);

      // Ping mỗi 25 giây để giữ kết nối sống (tránh Render/Cloud đóng socket)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendWs({'type': 'ping'});
      });
    } catch (e) {
      debugPrint('[WS] Lỗi kết nối WebSocket: $e');
      _isConnected = false;
      onConnectionChanged?.call(false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('[WS] Đang thử kết nối lại...');
        _doConnect();
      }
    });
  }

  void _sendWs(Map<String, dynamic> data) {
    try {
      _wsChannel?.sink.add(json.encode(data));
    } catch (e) {
      debugPrint('[WS] Lỗi gửi dữ liệu: $e');
    }
  }

  Future<void> _handleWsMessage(String rawMessage) async {
    try {
      final msg = json.decode(rawMessage) as Map<String, dynamic>;
      final type = msg['type']?.toString();

      if (type == 'registered') {
        debugPrint('[WS] ✅ Đã đăng ký thành công với server: ${msg['serverTime']}');
        _isConnected = true;
        onConnectionChanged?.call(true);
      } else if (type == 'pong') {
        // Server còn sống, giữ kết nối
      } else if (type == 'transaction_alert') {
        // NHẬN ĐƯỢC GIAO DỊCH TỪ MÁY A!
        final alertData = msg['alert'] as Map<String, dynamic>?;
        if (alertData != null) {
          final alert = TransactionAlert.fromMap(alertData);
          debugPrint('[WS] 💰 Nhận giao dịch: +${alert.amount} VND');

          // Kiểm tra chống trùng lặp local
          final storage = StorageService();
          await storage.init();

          if (!await storage.isEventProcessed(alert.eventId)) {
            await storage.markEventProcessed(alert.eventId);
            await storage.addTransactionToHistory(alert);

            // Hiển thị thông báo nổi
            final localNotif = LocalNotificationService();
            await localNotif.init();
            await localNotif.showTransactionNotification(alert);

            // Đọc giọng nói
            if (storage.getTtsEnabled()) {
              final tts = TtsService();
              await tts.init();
              final prefix = storage.getTtsPrefix();
              await tts.speakTransaction(alert, prefix: prefix);
            }

            // Callback cho provider cập nhật UI
            onAlertReceived?.call(alert);
          }
        }
      } else if (type == 'paired') {
        // THIẾT BỊ ĐỐI TÁC VỪA GHÉP CẶP THÀNH CÔNG
        final pairedId = msg['pairedDeviceId']?.toString();
        final pairedName = msg['pairedDeviceName']?.toString();
        debugPrint('[WS] ✅ Máy đối tác vừa ghép cặp: $pairedName ($pairedId)');

        if (pairedId != null && pairedId.isNotEmpty) {
          final storage = StorageService();
          await storage.init();
          await storage.savePairingInfo(
            pairedDeviceId: pairedId,
            pairedDeviceName: pairedName ?? 'Thiết bị đối tác',
          );
          onPairingUpdated?.call(pairedId, pairedName ?? 'Thiết bị đối tác');
        }
      }
    } catch (e) {
      debugPrint('[WS] Lỗi xử lý message: $e');
    }
  }

  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _isConnected = false;
  }

  /// Gửi sự kiện giao dịch từ Điện thoại A sang Server (HTTP POST)
  Future<RelayResult> forwardTransactionAlert({
    required TransactionAlert alert,
    required String senderDeviceId,
    String? targetDeviceId,
    String? serverUrl,
  }) async {
    final url = normalizeUrl(serverUrl);
    if (url.isEmpty) {
      return RelayResult(
        success: false,
        message: 'Chưa cấu hình địa chỉ Server chuyển tiếp',
      );
    }

    try {
      final endpoint = '$url/forwardAlert';
      final payload = {
        'alert': alert.toMap(),
        'senderDeviceId': senderDeviceId,
        'targetDeviceId': targetDeviceId,
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RelayResult(
          success: true,
          message: data['message']?.toString() ?? 'Đã chuyển tiếp thành công',
          data: data,
        );
      } else {
        return RelayResult(
          success: false,
          message: 'Lỗi máy chủ (HTTP ${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      return RelayResult(
        success: false,
        message: 'Hết thời gian chờ phản hồi từ máy chủ (Server đang khởi động lại)',
      );
    } catch (e) {
      debugPrint('[Relay] Lỗi kết nối: $e');
      return RelayResult(
        success: false,
        message: 'Không thể kết nối đến máy chủ: $e',
      );
    }
  }

  /// Đăng ký mã ghép nối lên server
  Future<bool> registerPairCode({
    required String code,
    required String currentDeviceId,
    required String currentDeviceName,
    String? serverUrl,
  }) async {
    final url = normalizeUrl(serverUrl);
    if (url.isEmpty) return false;

    try {
      final endpoint = '$url/registerPairCode';
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'pairCode': code.trim(),
              'deviceId': currentDeviceId,
              'deviceName': currentDeviceName,
            }),
          )
          .timeout(const Duration(seconds: 40));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Relay] Lỗi đăng ký mã ghép nối lên server: $e');
      return false;
    }
  }

  /// Ghép cặp qua server bằng mã ghép nối
  Future<RelayResult> pairWithCode({
    required String code,
    required String currentDeviceId,
    required String currentDeviceName,
    String? serverUrl,
  }) async {
    final url = normalizeUrl(serverUrl);
    if (url.isEmpty) {
      return RelayResult(
        success: true,
        message: 'Ghép cặp thành công (Chế độ mô phỏng - chưa cấu hình server)',
        data: {
          'pairedDeviceId': 'simulated-$code',
          'pairedDeviceName': 'Điện thoại ($code)',
        },
      );
    }

    try {
      final endpoint = '$url/pairDevice';
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'pairCode': code.trim(),
              'deviceId': currentDeviceId,
              'deviceName': currentDeviceName,
            }),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RelayResult(
          success: true,
          message: data['message']?.toString() ?? 'Ghép cặp thành công',
          data: data,
        );
      } else {
        try {
          final data = json.decode(response.body);
          return RelayResult(
            success: false,
            message: data['error']?.toString() ?? 'Mã ghép cặp không hợp lệ',
          );
        } catch (_) {
          return RelayResult(
            success: false,
            message: 'Lỗi server (HTTP ${response.statusCode})',
          );
        }
      }
    } on TimeoutException {
      return RelayResult(
        success: false,
        message: 'Server Render đang khởi động (mất ~30-45 giây). Vui lòng bấm Kết Nối lại sau vài giây!',
      );
    } catch (e) {
      return RelayResult(
        success: false,
        message: 'Lỗi mạng khi ghép cặp: $e',
      );
    }
  }

  /// Tự động ghép nối hai thiết bị đang kết nối tới cùng server
  Future<RelayResult> autoPair({
    required String currentDeviceId,
    required String currentDeviceName,
    String? serverUrl,
  }) async {
    final url = normalizeUrl(serverUrl);
    if (url.isEmpty) {
      return RelayResult(
        success: false,
        message: 'Vui lòng nhập địa chỉ URL máy chủ trước khi ghép cặp tự động',
      );
    }

    try {
      final endpoint = '$url/autoPair';
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'deviceId': currentDeviceId,
              'deviceName': currentDeviceName,
            }),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RelayResult(
          success: true,
          message: data['message']?.toString() ?? 'Ghép cặp tự động thành công!',
          data: data,
        );
      } else {
        try {
          final data = json.decode(response.body);
          return RelayResult(
            success: false,
            message: data['error']?.toString() ?? 'Không tìm thấy thiết bị đối tác trên server',
          );
        } catch (_) {
          return RelayResult(
            success: false,
            message: 'Lỗi server (HTTP ${response.statusCode})',
          );
        }
      }
    } on TimeoutException {
      return RelayResult(
        success: false,
        message: 'Server Render đang khởi động (mất ~30-45s). Vui lòng thử lại sau giây lát!',
      );
    } catch (e) {
      return RelayResult(
        success: false,
        message: 'Lỗi mạng khi ghép cặp tự động: $e',
      );
    }
  }
}
