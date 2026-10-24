import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_alert.dart';
import '../models/pairing_info.dart';

class RelayResult {
  final bool success;
  final String message;
  final dynamic data;

  RelayResult({required this.success, required this.message, this.data});
}

class RelayService {
  static final RelayService _instance = RelayService._internal();
  factory RelayService() => _instance;
  RelayService._internal();

  /// Gửi sự kiện giao dịch từ Điện thoại A sang Điện thoại B qua Cloud Functions / Server Relay
  Future<RelayResult> forwardTransactionAlert({
    required TransactionAlert alert,
    required PairingInfo pairingInfo,
  }) async {
    // Nếu ở chế độ Standalone (Kiểm thử 2-trong-1), không cần gửi qua mạng
    if (pairingInfo.role.name == 'standalone') {
      return RelayResult(
        success: true,
        message: 'Chế độ độc lập (Standalone) - Xử lý nội bộ',
      );
    }

    final serverUrl = pairingInfo.serverUrl?.trim();
    if (serverUrl == null || serverUrl.isEmpty) {
      return RelayResult(
        success: false,
        message: 'Chưa cấu hình địa chỉ Server / Firebase Cloud Functions',
      );
    }

    try {
      final endpoint = serverUrl.endsWith('/') ? '${serverUrl}forwardAlert' : '$serverUrl/forwardAlert';
      final payload = {
        'alert': alert.toMap(),
        'senderDeviceId': pairingInfo.deviceId,
        'targetDeviceId': pairingInfo.pairedDeviceId,
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return RelayResult(
          success: true,
          message: 'Đã chuyển tiếp thông báo đến thiết bị B thành công',
          data: response.body,
        );
      } else {
        return RelayResult(
          success: false,
          message: 'Lỗi máy chủ chuyển tiếp (HTTP ${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Lỗi kết nối chuyển tiếp thông báo: $e');
      return RelayResult(
        success: false,
        message: 'Không thể kết nối đến máy chủ: $e',
      );
    }
  }

  /// Ghép cặp hai thiết bị thông qua Mã Ghép Nối (Pair Code)
  Future<RelayResult> pairWithCode({
    required String code,
    required String currentDeviceId,
    required String currentDeviceName,
    String? serverUrl,
  }) async {
    if (serverUrl == null || serverUrl.isEmpty) {
      // Trong chế độ thử nghiệm cục bộ không cần server, chấp nhận mã ghép cặp
      return RelayResult(
        success: true,
        message: 'Đã ghép cặp thành công (Chế độ mô phỏng trực tiếp)',
        data: {
          'pairedDeviceId': 'simulated-device-$code',
          'pairedDeviceName': 'Điện thoại B ($code)',
        },
      );
    }

    try {
      final endpoint = serverUrl.endsWith('/') ? '${serverUrl}pairDevice' : '$serverUrl/pairDevice';
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RelayResult(
          success: true,
          message: 'Ghép cặp thành công',
          data: data,
        );
      } else {
        return RelayResult(
          success: false,
          message: 'Mã ghép cặp không hợp lệ hoặc đã hết hạn',
        );
      }
    } catch (e) {
      return RelayResult(
        success: false,
        message: 'Lỗi mạng khi ghép cặp: $e',
      );
    }
  }
}
