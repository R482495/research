import 'package:flutter/foundation.dart'; // ChangeNotifierを使用するためにFlutterのfoundationパッケージをインポートします。

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart'; // HearableデバイスSDKのサンプルプラグインをインポートします。

class Battery extends ChangeNotifier { // ChangeNotifierを拡張したBatteryクラス。
  final HearableDeviceSdkSamplePlugin _samplePlugin = HearableDeviceSdkSamplePlugin(); // HearableデバイスSDKのサンプルプラグインのインスタンスを作成。
  bool isEnabled = false; // バッテリ通知が有効かどうかを示すフラグ。

  int? _resultCode; // 操作の結果コードを格納する変数。
  Uint8List? _data; // バッテリ通知から受信したデータを格納する変数。

  static final Battery _instance = Battery._internal(); // Batteryクラスのシングルトンインスタンスを作成。

  factory Battery() { // シングルトンインスタンスを返すファクトリコンストラクタ。
    return _instance;
  }

  Battery._internal(); // シングルトンインスタンスを作成する内部コンストラクタ。

  int? get resultCode => _resultCode; // _resultCodeのゲッター。
  Uint8List? get data => _data; // _dataのゲッター。

  // 結果とデータの文字列表現を生成するメソッド。
  String getResultString() {
    String str = '';

    if (_resultCode != null) {
      str += 'result code: $_resultCode'; // 結果コードがnullでない場合、文字列に追加。
    }

    if (_data != null) {
      str += '\nbyte[]:\n';
      Uint8List data = _data!;
      for (int i = 0; i < data.length - 1; i++) {
        str += '${data[i].toRadixString(16)}, '; // データの各バイトを16進数形式で文字列に追加。
      }
      str += '${data.last.toRadixString(16)}\n';

      Uint8List percent = Uint8List.fromList(data.sublist(0,2)); // 最初の2バイトをバッテリのパーセンテージとして抽出。
      var percentBytes = percent.buffer.asByteData();
      str += '${percentBytes.getInt16(0, Endian.little)} %  '; // バッテリのパーセンテージを文字列に追加。

      Uint8List value = Uint8List.fromList(data.sublist(2,4)); // 次の2バイトをバッテリの電圧として抽出。
      var valueBytes = value.buffer.asByteData();
      str += '${valueBytes.getInt16(0, Endian.little)} mV'; // バッテリの電圧を文字列に追加。
    }

    return str; // 構築した文字列を返す。
  }

  // バッテリ通知のリスナーを追加するメソッド。
  Future<bool> addBatteryNotificationListener() async {
    final res = await _samplePlugin.addBatteryNotificationListener(
        onStartNotification: _onStartNotification,
        onStopNotification: _onStopNotification,
        onReceiveNotification: _onReceiveNotification
    );
    return res; // リスナーの追加結果を返す。
  }

  // バッテリ通知のリスナーを削除するメソッド。
  void _removeBatteryNotificationListener() {
    _samplePlugin.removeBatteryNotificationListener();
  }

  // 通知開始時に呼び出されるコールバック。
  void _onStartNotification(int resultCode) {
    _resultCode = resultCode;
    notifyListeners(); // リスナーに変更を通知。
  }

  // 通知停止時に呼び出されるコールバック。
  void _onStopNotification(int resultCode) {
    _removeBatteryNotificationListener(); // バッテリ通知のリスナーを削除。
    _resultCode = resultCode;
    notifyListeners(); // リスナーに変更を通知。
  }

  // 通知受信時に呼び出されるコールバック。
  void _onReceiveNotification(Uint8List? data, int resultCode) {
    _data = data;
    _resultCode = resultCode;
    notifyListeners(); // リスナーに変更を通知。
  }
}
