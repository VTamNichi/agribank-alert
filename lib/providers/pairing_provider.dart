import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/models/pairing_info.dart';
import '../core/services/relay_service.dart';
import '../core/services/storage_service.dart';

class PairingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final RelayService _relay = RelayService();

  late PairingInfo _pairingInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  PairingInfo get pairingInfo => _pairingInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> init() async {
    await _storage.init();
    _pairingInfo = _storage.getPairingInfo();

    // Lắng nghe sự kiện ghép cặp thành công từ đối tác qua WebSocket
    _relay.onPairingUpdated = (pairedId, pairedName) async {
      await _storage.savePairingInfo(
        pairedDeviceId: pairedId,
        pairedDeviceName: pairedName,
      );
      _pairingInfo = _storage.getPairingInfo();
      _successMessage = 'Đã kết nối thành công với $pairedName!';
      _errorMessage = null;
      notifyListeners();
    };

    if (_pairingInfo.pairCode == null || _pairingInfo.pairCode!.isEmpty) {
      await generateNewPairCode();
    } else {
      await _syncPairCodeToServer(_pairingInfo.pairCode!);
    }
    notifyListeners();
  }

  Future<void> generateNewPairCode() async {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    final code = 'AG-$number';
    await _storage.savePairingInfo(pairCode: code);
    _pairingInfo = _storage.getPairingInfo();
    await _syncPairCodeToServer(code);
    notifyListeners();
  }

  Future<void> _syncPairCodeToServer(String code) async {
    if (_pairingInfo.serverUrl != null && _pairingInfo.serverUrl!.isNotEmpty) {
      await _relay.registerPairCode(
        code: code,
        currentDeviceId: _pairingInfo.deviceId,
        currentDeviceName: _pairingInfo.deviceName,
        serverUrl: _pairingInfo.serverUrl,
      );
    }
  }

  Future<bool> pairWithCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _relay.pairWithCode(
      code: code,
      currentDeviceId: _pairingInfo.deviceId,
      currentDeviceName: _pairingInfo.deviceName,
      serverUrl: _pairingInfo.serverUrl,
    );

    _isLoading = false;
    if (result.success) {
      final data = result.data as Map<String, dynamic>?;
      final pairedId = data?['pairedDeviceId']?.toString() ?? 'device-$code';
      final pairedName = data?['pairedDeviceName']?.toString() ?? 'Máy B ($code)';

      await _storage.savePairingInfo(
        pairedDeviceId: pairedId,
        pairedDeviceName: pairedName,
      );
      _pairingInfo = _storage.getPairingInfo();
      _successMessage = result.message;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<RelayResult> testServerConnection(String? url) async {
    return await _relay.testServerConnection(url ?? _pairingInfo.serverUrl);
  }

  Future<bool> autoPair() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _relay.autoPair(
      currentDeviceId: _pairingInfo.deviceId,
      currentDeviceName: _pairingInfo.deviceName,
      serverUrl: _pairingInfo.serverUrl,
    );

    _isLoading = false;
    if (result.success) {
      final data = result.data as Map<String, dynamic>?;
      final pairedId = data?['pairedDeviceId']?.toString() ?? 'device-auto';
      final pairedName = data?['pairedDeviceName']?.toString() ?? 'Thiết bị đối tác';

      await _storage.savePairingInfo(
        pairedDeviceId: pairedId,
        pairedDeviceName: pairedName,
      );
      _pairingInfo = _storage.getPairingInfo();
      _successMessage = result.message;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> unpair() async {
    await _storage.clearPairing();
    _pairingInfo = _storage.getPairingInfo();
    _successMessage = 'Đã hủy ghép cặp thiết bị';
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    final cleanUrl = RelayService.normalizeUrl(url);
    await _storage.savePairingInfo(serverUrl: cleanUrl);
    _pairingInfo = _storage.getPairingInfo();
    if (_pairingInfo.pairCode != null) {
      await _syncPairCodeToServer(_pairingInfo.pairCode!);
    }
    notifyListeners();
  }
}
