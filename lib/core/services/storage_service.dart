import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/device_role.dart';
import '../models/pairing_info.dart';
import '../models/transaction_alert.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  static const String _keyDeviceId = 'device_id';
  static const String _keyDeviceName = 'device_name';
  static const String _keyDeviceRole = 'device_role';
  static const String _keyPairCode = 'pair_code';
  static const String _keyPairedDeviceId = 'paired_device_id';
  static const String _keyPairedDeviceName = 'paired_device_name';
  static const String _keyServerUrl = 'server_url';
  static const String _keyHistory = 'transaction_history';
  static const String _keyProcessedIds = 'processed_event_ids';
  static const String _keyTtsEnabled = 'tts_enabled';
  static const String _keyTtsVolume = 'tts_volume';
  static const String _keyTtsRate = 'tts_rate';
  static const String _keyTtsPrefix = 'tts_prefix';
  static const String _keyMonitoredPackages = 'monitored_packages_list';
  static const String _keyMaxAmountFilterEnabled = 'max_amount_filter_enabled';
  static const String _keyMaxAmountLimit = 'max_amount_limit';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Device Info
  String getDeviceId() {
    String? id = _prefs?.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4().substring(0, 8);
      _prefs?.setString(_keyDeviceId, id);
    }
    return id;
  }

  String getDeviceName() {
    return _prefs?.getString(_keyDeviceName) ?? 'Thiết bị Agribank';
  }

  Future<void> setDeviceName(String name) async {
    await _prefs?.setString(_keyDeviceName, name);
  }

  DeviceRole getDeviceRole() {
    final int roleIndex = _prefs?.getInt(_keyDeviceRole) ?? DeviceRole.standalone.index;
    if (roleIndex >= 0 && roleIndex < DeviceRole.values.length) {
      return DeviceRole.values[roleIndex];
    }
    return DeviceRole.standalone;
  }

  Future<void> setDeviceRole(DeviceRole role) async {
    await _prefs?.setInt(_keyDeviceRole, role.index);
  }

  // Pairing Info
  PairingInfo getPairingInfo() {
    final deviceId = getDeviceId();
    final deviceName = getDeviceName();
    final role = getDeviceRole();
    final pairCode = _prefs?.getString(_keyPairCode);
    final pairedDeviceId = _prefs?.getString(_keyPairedDeviceId);
    final pairedDeviceName = _prefs?.getString(_keyPairedDeviceName);
    final isPaired = pairedDeviceId != null && pairedDeviceId.isNotEmpty;
    final serverUrl = _prefs?.getString(_keyServerUrl);

    return PairingInfo(
      isPaired: isPaired,
      deviceId: deviceId,
      deviceName: deviceName,
      pairCode: pairCode,
      pairedDeviceId: pairedDeviceId,
      pairedDeviceName: pairedDeviceName,
      role: role,
      serverUrl: serverUrl,
    );
  }

  Future<void> savePairingInfo({
    String? pairCode,
    String? pairedDeviceId,
    String? pairedDeviceName,
    String? serverUrl,
  }) async {
    if (pairCode != null) await _prefs?.setString(_keyPairCode, pairCode);
    if (pairedDeviceId != null) await _prefs?.setString(_keyPairedDeviceId, pairedDeviceId);
    if (pairedDeviceName != null) await _prefs?.setString(_keyPairedDeviceName, pairedDeviceName);
    if (serverUrl != null) await _prefs?.setString(_keyServerUrl, serverUrl);
  }

  Future<void> clearPairing() async {
    await _prefs?.remove(_keyPairedDeviceId);
    await _prefs?.remove(_keyPairedDeviceName);
  }

  // Chống trùng lặp (Duplicate Detection)
  List<String> getProcessedEventIds() {
    return _prefs?.getStringList(_keyProcessedIds) ?? [];
  }

  Future<bool> isEventProcessed(String eventId) async {
    final list = getProcessedEventIds();
    return list.contains(eventId);
  }

  Future<void> markEventProcessed(String eventId) async {
    final list = getProcessedEventIds();
    if (!list.contains(eventId)) {
      list.add(eventId);
      // Giữ tối đa 500 sự kiện gần nhất
      final trimmed = list.length > 500 ? list.sublist(list.length - 500) : list;
      await _prefs?.setStringList(_keyProcessedIds, trimmed);
    }
  }

  // Lịch sử giao dịch (History)
  List<TransactionAlert> getHistory() {
    final raw = _prefs?.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => TransactionAlert.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addTransactionToHistory(TransactionAlert alert) async {
    final history = getHistory();
    // Chèn mới lên đầu danh sách
    history.insert(0, alert);
    // Giữ tối đa 200 bản ghi lịch sử
    final trimmed = history.length > 200 ? history.sublist(0, 200) : history;
    final jsonList = trimmed.map((e) => e.toMap()).toList();
    await _prefs?.setString(_keyHistory, json.encode(jsonList));
  }

  Future<void> clearHistory() async {
    await _prefs?.remove(_keyHistory);
  }

  // Settings
  bool getTtsEnabled() => _prefs?.getBool(_keyTtsEnabled) ?? true;
  Future<void> setTtsEnabled(bool val) async => await _prefs?.setBool(_keyTtsEnabled, val);

  double getTtsVolume() => _prefs?.getDouble(_keyTtsVolume) ?? 1.0;
  Future<void> setTtsVolume(double val) async => await _prefs?.setDouble(_keyTtsVolume, val);

  double getTtsRate() => _prefs?.getDouble(_keyTtsRate) ?? 0.5;
  Future<void> setTtsRate(double val) async => await _prefs?.setDouble(_keyTtsRate, val);

  String getTtsPrefix() => _prefs?.getString(_keyTtsPrefix) ?? 'Bạn vừa nhận';
  Future<void> setTtsPrefix(String val) async => await _prefs?.setString(_keyTtsPrefix, val);

  List<String> getMonitoredPackages() {
    return _prefs?.getStringList(_keyMonitoredPackages) ??
        [
          'com.vnpay.Agribank3g',
          'com.google.android.apps.messaging',
          'com.samsung.android.messaging',
          'com.android.mms',
          'com.agribankalert.agribank_alert',
        ];
  }

  Future<void> setMonitoredPackages(List<String> pkgs) async {
    await _prefs?.setStringList(_keyMonitoredPackages, pkgs);
  }

  // Lọc số tiền tối đa (mặc định chỉ bắn thông báo dưới 10 triệu)
  bool getMaxAmountFilterEnabled() => _prefs?.getBool(_keyMaxAmountFilterEnabled) ?? true;
  Future<void> setMaxAmountFilterEnabled(bool val) async =>
      await _prefs?.setBool(_keyMaxAmountFilterEnabled, val);

  double getMaxAmountLimit() => _prefs?.getDouble(_keyMaxAmountLimit) ?? 10000000.0;
  Future<void> setMaxAmountLimit(double val) async =>
      await _prefs?.setDouble(_keyMaxAmountLimit, val);
}
