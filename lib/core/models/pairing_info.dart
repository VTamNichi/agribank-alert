import 'dart:convert';
import 'device_role.dart';

class PairingInfo {
  final bool isPaired;
  final String deviceId;
  final String deviceName;
  final String? pairCode;
  final String? pairedDeviceId;
  final String? pairedDeviceName;
  final DateTime? pairedAt;
  final DeviceRole role;
  final String? serverUrl;

  PairingInfo({
    this.isPaired = false,
    required this.deviceId,
    required this.deviceName,
    this.pairCode,
    this.pairedDeviceId,
    this.pairedDeviceName,
    this.pairedAt,
    this.role = DeviceRole.standalone,
    this.serverUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'isPaired': isPaired,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'pairCode': pairCode,
      'pairedDeviceId': pairedDeviceId,
      'pairedDeviceName': pairedDeviceName,
      'pairedAt': pairedAt?.toIso8601String(),
      'role': role.index,
      'serverUrl': serverUrl,
    };
  }

  factory PairingInfo.fromMap(Map<String, dynamic> map) {
    return PairingInfo(
      isPaired: map['isPaired'] == true,
      deviceId: map['deviceId']?.toString() ?? '',
      deviceName: map['deviceName']?.toString() ?? 'Thiết bị Agribank',
      pairCode: map['pairCode']?.toString(),
      pairedDeviceId: map['pairedDeviceId']?.toString(),
      pairedDeviceName: map['pairedDeviceName']?.toString(),
      pairedAt: map['pairedAt'] != null ? DateTime.tryParse(map['pairedAt'].toString()) : null,
      role: (map['role'] != null && map['role'] is int && map['role'] < DeviceRole.values.length)
          ? DeviceRole.values[map['role'] as int]
          : DeviceRole.standalone,
      serverUrl: map['serverUrl']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PairingInfo.fromJson(String source) =>
      PairingInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  PairingInfo copyWith({
    bool? isPaired,
    String? deviceId,
    String? deviceName,
    String? pairCode,
    String? pairedDeviceId,
    String? pairedDeviceName,
    DateTime? pairedAt,
    DeviceRole? role,
    String? serverUrl,
  }) {
    return PairingInfo(
      isPaired: isPaired ?? this.isPaired,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      pairCode: pairCode ?? this.pairCode,
      pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
      pairedDeviceName: pairedDeviceName ?? this.pairedDeviceName,
      pairedAt: pairedAt ?? this.pairedAt,
      role: role ?? this.role,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}
