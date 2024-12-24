import 'package:flutter/foundation.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

// デバイス情報を保持するクラス
class DeviceInfo {
  final String deviceId; // デバイスのID
  final String name; // デバイスの名前
  final int rssi; // デバイスの受信信号強度

  // 構造体(ファクトリコンストラクタ)
  const DeviceInfo({
    required this.deviceId,
    required this.name,
    required this.rssi,
  });

  // DeviceInfoオブジェクトを生成するファクトリコンストラクタ
  factory DeviceInfo.fromMap(Map<String, dynamic> info) {
    return DeviceInfo(
      deviceId: info['deviceId'] as String,
      name: info['name'] as String,
      rssi: info['rssi'] as int,
    );
  }
}

// Bluetoothデバイスの管理を行うクラス
class BluetoothManager extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin = HearableDeviceSdkSamplePlugin(); // サンプルプラグインのインスタンス

  bool _isConnected = false; // デバイスが接続されているかどうか
  String _deviceName = ""; // 接続されているデバイスの名前
  int _resultCode = 0; // 操作の結果コード
  final List<DeviceInfo> _deviceList = []; // 検出されたデバイスのリスト

  // コールバック関数を保持するプロパティ
  Function(int)? _connectCallback;
  Function(int)? _disconnectCallback;
  Function(int)? _scanCallback;

  // シングルトンインスタンスの生成
  static final BluetoothManager _instance = BluetoothManager._internal();

  // ファクトリコンストラクタ
  factory BluetoothManager() {
    return _instance;
  }

  // プライベートコンストラクタ
  BluetoothManager._internal();

  // ゲッター
  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  int get resultCode => _resultCode;
  List<DeviceInfo> get deviceList => _deviceList;

  // デバイスの状態リスナーを登録するメソッド
  Future<bool> registHearableStatusListener() async {
    final res = await _samplePlugin.registHearableStatusListener(onChangeStatus: _onChangeStatus);
    return res;
  }

  // BLEリスナーを追加するメソッド
  Future<bool> addHearableBleListener({
    required Function(int)? connectCallback,
    required Function(int)? disconnectCallback,
    required Function(int)? scanCallback,
  }) async {
    _connectCallback = connectCallback;
    _disconnectCallback = disconnectCallback;
    _scanCallback = scanCallback;

    print("addHearableBleListener");
    final res = await _samplePlugin.addHearableBleListener(
      onConnect: _onConnect,
      onDisconnect: _onDisconnect,
      onScanResult: _onScanResult,
    );
    return res;
  }

  // デバイスの状態リスナーを解除するメソッド
  Future<bool> unregistHearableStatusListener() async {
    final res = await _samplePlugin.unregistHearableStatusListener();
    return res;
  }

  // BLEリスナーを解除するメソッド
  Future<bool> removeHearableBleListener() async {
    final res = await _samplePlugin.removeHearableBleListener();
    return res;
  }

  // 接続状態やコールバックをリセットするメソッド
  void reset() {
    _isConnected = false;
    _deviceName = "";
    _connectCallback = null;
    _disconnectCallback = null;
    _scanCallback = null;
  }

  // 接続時のコールバック処理
  void _onConnect(int resultCode) {
    _resultCode = resultCode;
    if (_connectCallback != null) {
      _connectCallback!(resultCode);
    }
    notifyListeners(); // 状態の変化を通知
  }

  // 切断時のコールバック処理
  void _onDisconnect(int resultCode) {
    _resultCode = resultCode;
    if (_disconnectCallback != null) {
      _disconnectCallback!(resultCode);
    }
    notifyListeners(); // 状態の変化を通知
  }

  // スキャン結果のコールバック処理
  void _onScanResult(List<Map<String, dynamic>>? deviceList, int resultCode) {
    _deviceList.clear();
    if (resultCode == 0 && deviceList != null) {
      for (Map<String, dynamic> info in deviceList) {
        _deviceList.add(DeviceInfo.fromMap(info));
      }
    }

    _resultCode = resultCode;
    if (_scanCallback != null) {
      _scanCallback!(resultCode);
    }
    notifyListeners(); // 状態の変化を通知
  }

  // デバイスの状態変化のコールバック処理
  void _onChangeStatus(Map<String, dynamic> hearableStatus) {
    _isConnected = hearableStatus['isConnected'] as bool;
    _deviceName = hearableStatus['deviceName'] as String;
    notifyListeners(); // 状態の変化を通知
  }
}
