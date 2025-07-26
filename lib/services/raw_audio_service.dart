import 'dart:async';
import 'dart:io';

import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/services/text_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ble.dart';

class RawAudioService {
  RawAudioService._();
  static final RawAudioService _instance = RawAudioService._();
  static RawAudioService get instance => _instance;

  /// interval in seconds for detecting both touch pads touched
  double touchInterval = 0.5;

  bool _isRecording = false;
  List<int> _recorded = [];

  StreamSubscription<BleReceive>? _sub;
  Timer? _timer;

  DateTime? _leftTime;
  DateTime? _rightTime;

  final ValueNotifier<String?> lastSavedFile = ValueNotifier(null);

  void start() {
    _sub ??= BleManager.get().eventBleReceive.listen(_onEvent);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _timer?.cancel();
    _timer = null;
  }

  void _onEvent(BleReceive res) {
    if (res.type == 'VoiceChunk') {
      if (_isRecording) {
        _recorded.addAll(res.data);
      }
      return;
    }
    if (res.data.isEmpty) return;
    if (res.data[0] == 0xF5 && res.data[1] == 0x01) {
      var now = DateTime.now();
      if (res.lr == 'L') _leftTime = now;
      if (res.lr == 'R') _rightTime = now;
      if (_leftTime != null && _rightTime != null) {
        var diff = _leftTime!.difference(_rightTime!).abs().inMilliseconds;
        if (diff <= (touchInterval * 1000).round()) {
          _toggleRecording();
          _leftTime = null;
          _rightTime = null;
        }
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      _isRecording = true;
      _recorded.clear();
      TextService.get.startSendText(
          'In Raw Recording Mode, max 60 seconds, tap both touch pad to end');
      await Proto.micOn(lr: 'R');
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 60), () => stopRecording());
    } else {
      await stopRecording();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _timer?.cancel();
    await Proto.exit();
    TextService.get.startSendText('Recording ended');
    await Future.delayed(const Duration(seconds: 5));
    await _saveToFile();
  }

  Future<void> _saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/raw_${DateTime.now().millisecondsSinceEpoch}.bin');
      await file.writeAsBytes(_recorded);
      lastSavedFile.value = file.path;
    } catch (e) {
      print('Error saving file: $e');
    }
  }
}
