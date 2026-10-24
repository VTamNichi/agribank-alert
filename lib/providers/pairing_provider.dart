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
    if (_pairingInfo.pairCode == null || _pairingInfo.pairCode!.isEmpty) {
      await generateNewPairCode();
    }
    notifyListeners();
  }

  Future<void> generateNewPairCode() async {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    final code = 'AG-$number';
    await _storage.savePairingInfo(pairCode: code);
    _pairingInfo = _storage.getPairingInfo();
    notifyListeners();
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

  Future<void> unpair() async {
    await _storage.clearPairing();
    _pairingInfo = _storage.getPairingInfo();
    _successMessage = 'Đã hủy ghép cặp thiết bị';
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    await _storage.savePairingInfo(serverUrl: url.trim());
    _pairingInfo = _storage.getPairingInfo();
    notifyListeners();
  }
}
