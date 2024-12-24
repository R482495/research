import 'package:flutter/foundation.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';
class HeartRate extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  bool isEnabled = false;
  int? _resultCode;
  Uint8List? _data;
  static final HeartRate _instance = HeartRate._internal();
  factory HeartRate() {
    return _instance;
  }
  HeartRate._internal();
  int? get resultCode => _resultCode;
  Uint8List? get data => _data;
  String getResultString() {
    String str = '';
    if (_resultCode != null) {
      str += 'result code: $_resultCode';
    }
    if (_data != null) {
      str += '\nbyte[]:\n';
      Uint8List data = _data!;
      for (int i = 0; i < data.length - 1; i++) {
        str += '${data[i].toRadixString(16)}, ';
      }
      str += '${data.last.toRadixString(16)}\n';
      str += '${data.first} bpm';
    }
    return str;
  }
  String getHR() {
    String str = '';
    String res = '';
    if (_resultCode != null) {
      str += 'result code: $_resultCode';
    }
    if (_data != null) {
      str += '\nbyte[]:\n';
      Uint8List data = _data!;
      for (int i = 0; i < data.length - 1; i++) {
        str += '${data[i].toRadixString(16)}, ';
      }
      str += '${data.last.toRadixString(16)}\n';
      res += '${data.first} bpm';
      str += res;
    }
    return res;
  }

  int? getBPM() {//null�̉\���傾����int?ninaru!!!!
    if (_data != null && _data!.isNotEmpty) {
      return _data!.first;
    }
    return null; // �f�[�^���Ȃ��ꍇ��G���[��
  }

  Future<bool> addHeartRateNotificationListener() async {
    final res = await _samplePlugin.addHeartRateNotificationListener(
        onStartNotification: _onStartNotification,
        onStopNotification: _onStopNotification,
        onReceiveNotification: _onReceiveNotification);
    return res;
  }
  void removeHeartRateNotificationListener() {
    _samplePlugin.removeHeartRateNotificationListener();
  }
  void _onStartNotification(int resultCode) {
    _resultCode = resultCode;
    notifyListeners();
  }
  void _onStopNotification(int resultCode) {
    removeHeartRateNotificationListener();
    _resultCode = resultCode;
    notifyListeners();
  }
  void _onReceiveNotification(Uint8List? data, int resultCode) {
    _data = data;
    _resultCode = resultCode;
    notifyListeners();
  }
}