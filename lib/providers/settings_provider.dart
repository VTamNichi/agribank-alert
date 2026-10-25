import 'package:flutter/foundation.dart';
import '../core/models/device_role.dart';
import '../core/services/notification_listener_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final TtsService _tts = TtsService();
  final NativeNotificationListenerService _native = NativeNotificationListenerService();

  late DeviceRole _role;
  late String _deviceId;
  late String _deviceName;
  late bool _ttsEnabled;
  late double _ttsVolume;
  late double _ttsRate;
  late String _ttsPrefix;
  late List<String> _monitoredPackages;
  late bool _maxAmountFilterEnabled;
  late double _maxAmountLimit;

  DeviceRole get role => _role;
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  bool get ttsEnabled => _ttsEnabled;
  double get ttsVolume => _ttsVolume;
  double get ttsRate => _ttsRate;
  String get ttsPrefix => _ttsPrefix;
  List<String> get monitoredPackages => _monitoredPackages;
  bool get maxAmountFilterEnabled => _maxAmountFilterEnabled;
  double get maxAmountLimit => _maxAmountLimit;

  Future<void> init() async {
    await _storage.init();
    _deviceId = _storage.getDeviceId();
    _deviceName = _storage.getDeviceName();
    _role = _storage.getDeviceRole();
    _ttsEnabled = _storage.getTtsEnabled();
    _ttsVolume = _storage.getTtsVolume();
    _ttsRate = _storage.getTtsRate();
    _ttsPrefix = _storage.getTtsPrefix();
    _monitoredPackages = _storage.getMonitoredPackages();
    _maxAmountFilterEnabled = _storage.getMaxAmountFilterEnabled();
    _maxAmountLimit = _storage.getMaxAmountLimit();
    notifyListeners();
  }

  Future<void> setRole(DeviceRole newRole) async {
    _role = newRole;
    await _storage.setDeviceRole(newRole);
    notifyListeners();
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    await _storage.setDeviceName(name);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    await _storage.setTtsEnabled(enabled);
    _tts.updateSettings(isEnabled: enabled);
    notifyListeners();
  }

  Future<void> setTtsVolume(double vol) async {
    _ttsVolume = vol;
    await _storage.setTtsVolume(vol);
    _tts.updateSettings(volume: vol);
    notifyListeners();
  }

  Future<void> setTtsRate(double rate) async {
    _ttsRate = rate;
    await _storage.setTtsRate(rate);
    _tts.updateSettings(rate: rate);
    notifyListeners();
  }

  Future<void> setTtsPrefix(String prefix) async {
    _ttsPrefix = prefix;
    await _storage.setTtsPrefix(prefix);
    notifyListeners();
  }

  Future<void> testTtsVoice() async {
    await _tts.speak('$_ttsPrefix năm trăm nghìn đồng');
  }

  Future<void> setMonitoredPackages(List<String> packages) async {
    _monitoredPackages = packages;
    await _storage.setMonitoredPackages(packages);
    await _native.setMonitoredPackages(packages);
    notifyListeners();
  }

  // Lọc số tiền tối đa
  Future<void> setMaxAmountFilterEnabled(bool enabled) async {
    _maxAmountFilterEnabled = enabled;
    await _storage.setMaxAmountFilterEnabled(enabled);
    notifyListeners();
  }

  Future<void> setMaxAmountLimit(double limit) async {
    _maxAmountLimit = limit;
    await _storage.setMaxAmountLimit(limit);
    notifyListeners();
  }
}
