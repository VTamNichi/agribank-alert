import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/transaction_alert.dart';
import 'vietnamese_number_to_words.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _volume = 1.0;
  double _rate = 0.5; // Tốc độ chuẩn đọc tiếng Việt rõ ràng
  double _pitch = 1.0;
  bool _isEnabled = true;

  final List<String> _speechQueue = [];

  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  double get rate => _rate;
  double get pitch => _pitch;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Cấu hình ngôn ngữ tiếng Việt
      await _flutterTts!.setLanguage("vi-VN");
      await _flutterTts!.setSpeechRate(_rate);
      await _flutterTts!.setVolume(_volume);
      await _flutterTts!.setPitch(_pitch);

      _flutterTts!.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isPlaying = false;
        _processQueue();
      });

      _flutterTts!.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
        _isPlaying = false;
        _processQueue();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("Lỗi khởi tạo TTS: $e");
    }
  }

  void updateSettings({
    bool? isEnabled,
    double? volume,
    double? rate,
    double? pitch,
  }) {
    if (isEnabled != null) _isEnabled = isEnabled;
    if (volume != null) {
      _volume = volume;
      _flutterTts?.setVolume(volume);
    }
    if (rate != null) {
      _rate = rate;
      _flutterTts?.setSpeechRate(rate);
    }
    if (pitch != null) {
      _pitch = pitch;
      _flutterTts?.setPitch(pitch);
    }
  }

  Future<void> speakTransaction(
    TransactionAlert alert, {
    String prefix = 'Bạn vừa nhận',
    bool mentionSender = false,
  }) async {
    if (!_isEnabled) return;

    String words = VietnameseNumberToWords.convert(alert.amount);
    String phrase = '$prefix $words';

    if (mentionSender && alert.senderName != null && alert.senderName!.isNotEmpty) {
      phrase += ' từ ${alert.senderName}';
    }

    await speak(phrase);
  }

  Future<void> speak(String text) async {
    if (!_isEnabled) return;
    if (!_isInitialized) await init();

    _speechQueue.add(text);
    if (!_isPlaying) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_speechQueue.isEmpty || _isPlaying) return;

    final nextText = _speechQueue.removeAt(0);
    _isPlaying = true;

    try {
      await _flutterTts?.speak(nextText);
    } catch (e) {
      debugPrint("Lỗi phát âm TTS: $e");
      _isPlaying = false;
      _processQueue();
    }
  }

  Future<void> stop() async {
    _speechQueue.clear();
    _isPlaying = false;
    await _flutterTts?.stop();
  }
}
