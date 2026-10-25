import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeNotificationListenerService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.agribankalert/notification_listener');
  static const EventChannel _eventChannel =
      EventChannel('com.agribankalert/notification_stream');

  StreamSubscription? _subscription;

  /// Kiểm tra xem ứng dụng đã được người dùng cấp quyền Notification Listener chưa
  Future<bool> isPermissionGranted() async {
    try {
      final bool granted =
          await _methodChannel.invokeMethod('isNotificationListenerPermissionGranted');
      return granted;
    } catch (e) {
      debugPrint('Lỗi kiểm tra quyền Notification Listener: $e');
      return false;
    }
  }

  /// Mở màn hình Cài đặt Android để người dùng bật Notification Access
  Future<bool> openSettings() async {
    try {
      final bool opened =
          await _methodChannel.invokeMethod('openNotificationListenerSettings');
      return opened;
    } catch (e) {
      debugPrint('Lỗi mở cài đặt Notification Listener: $e');
      return false;
    }
  }

  /// Kiểm tra trạng thái bỏ qua tối ưu hóa pin (tránh Android tắt background service)
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool ignored =
          await _methodChannel.invokeMethod('isBatteryOptimizationIgnored');
      return ignored;
    } catch (e) {
      debugPrint('Lỗi kiểm tra tối ưu hóa pin: $e');
      return false;
    }
  }

  /// Yêu cầu bỏ qua tối ưu hóa pin
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final bool requested =
          await _methodChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      return requested;
    } catch (e) {
      debugPrint('Lỗi xin bỏ qua tối ưu pin: $e');
      return false;
    }
  }

  /// Lắng nghe stream thông báo thời gian thực từ Android NotificationListenerService
  void startListening(Function(Map<String, dynamic> data) onData) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final map = Map<String, dynamic>.from(event);
          onData(map);
        }
      },
      onError: (dynamic error) {
        debugPrint('Lỗi Stream Notification Listener: $error');
      },
    );
  }

  /// Dừng lắng nghe
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Lấy danh sách các thông báo đã lưu trong hàng đợi khi app chưa mở
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final List<dynamic>? list =
          await _methodChannel.invokeMethod('getPendingNotifications');
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Lỗi lấy thông báo hàng đợi: $e');
      return [];
    }
  }

  /// Xóa thông báo hàng đợi đã xử lý
  Future<void> clearPendingNotifications() async {
    try {
      await _methodChannel.invokeMethod('clearPendingNotifications');
    } catch (e) {
      debugPrint('Lỗi xóa hàng đợi thông báo: $e');
    }
  }

  /// Lấy danh sách package name đang theo dõi
  Future<List<String>> getMonitoredPackages() async {
    try {
      final List<dynamic>? list =
          await _methodChannel.invokeMethod('getMonitoredPackages');
      if (list == null) return [];
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return ['com.vnpay.Agribank3g'];
    }
  }

  /// Cập nhật danh sách package name theo dõi
  Future<void> setMonitoredPackages(List<String> packages) async {
    try {
      await _methodChannel.invokeMethod('setMonitoredPackages', {'packages': packages});
    } catch (e) {
      debugPrint('Lỗi cấu hình package theo dõi: $e');
    }
  }

  /// Đẩy thông báo mẫu thử nghiệm vào hệ thống Android
  Future<bool> sendTestNotification({
    String title = 'Agribank Alert Test',
    String content = 'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien',
  }) async {
    try {
      final bool sent = await _methodChannel.invokeMethod('sendTestNotification', {
        'title': title,
        'content': content,
      });
      return sent;
    } catch (e) {
      debugPrint('Lỗi gửi thông báo test: $e');
      return false;
    }
  }

  /// Khởi động dịch vụ chạy ngầm chuyên dụng (Foreground Service)
  Future<bool> startForegroundService() async {
    try {
      final bool started = await _methodChannel.invokeMethod('startForegroundService');
      return started;
    } catch (e) {
      debugPrint('Lỗi khởi động Foreground Service: $e');
      return false;
    }
  }

  /// Dừng dịch vụ chạy ngầm chuyên dụng
  Future<bool> stopForegroundService() async {
    try {
      final bool stopped = await _methodChannel.invokeMethod('stopForegroundService');
      return stopped;
    } catch (e) {
      debugPrint('Lỗi dừng Foreground Service: $e');
      return false;
    }
  }

  /// Kiểm tra xem Foreground Service có đang chạy không
  Future<bool> isForegroundServiceRunning() async {
    try {
      final bool running = await _methodChannel.invokeMethod('isForegroundServiceRunning');
      return running;
    } catch (e) {
      return false;
    }
  }
}
