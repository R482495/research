import 'package:flutter/foundation.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; //add

 late AudioPlayer audioPlayer;///////////////////////////////add
  bool isPlaying = false; // 音楽が再生中かどうかを示す
  bool shouldContinue = true; // ループを制御する
  double volume = 0.5;
  bool isIncreasing = true;
  final double volumeStep = 0.05;//音量の上げていく量

class NineAxisSensor extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  bool isEnabled = false;

  int? _resultCode;
  Uint8List? _data;
   bool isShaking = false; // 頭の振りが検出されたかどうかを示す//////////////////////////

  static final NineAxisSensor _instance = NineAxisSensor._internal();

  factory NineAxisSensor() {
    return _instance;
  }

  NineAxisSensor._internal();

  int? get resultCode => _resultCode;
  Uint8List? get data => _data;

  // HeadShakeDetector インスタンスを追加
  final HeadShakeDetector _headShakeDetector = HeadShakeDetector();

  // センサーデータから加速度とジャイロデータを抽出するメソッド
  List<String> getHexAccelDataBatch() {
    // オフセット定数
    int accXoffset = 5;
    int accYoffset = 7;
    int accZoffset = 9;
    int gyrXoffset = 11;
    int gyrYoffset = 13;
    int gyrZoffset = 15;

    // データの初期化
    String accX = "";
    String accY = "";
    String accZ = "";
    String gyrX = "";
    String gyrY = "";
    String gyrZ = "";

    // データが存在する場合に処理を実行
    if (_data != null) {
      Uint8List data = _data!;
      // データバッチを作成（5つのデータポイント）
      for (int i = 0; i < 5; i++) {
        accX +=
            '${data[accXoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[accXoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';
        accY +=
            '${data[accYoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[accYoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';
        accZ +=
            '${data[accZoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[accZoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';

        gyrX +=
            '${data[gyrXoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[gyrXoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';
        gyrY +=
            '${data[gyrYoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[gyrYoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';
        gyrZ +=
            '${data[gyrZoffset + (i * 22)].toRadixString(16).padLeft(2, '0')}${data[gyrZoffset + 1 + (i * 22)].toRadixString(16).padLeft(2, '0')}';
      }
    }

    // 加速度データとジャイロデータをバッチとして返す
    List<String> accelDataBatch = [
      accX,
      accY,
      accZ,
      gyrX,
      gyrY,
      gyrZ,
    ];
    return accelDataBatch;
  }

  // データの結果を文字列形式で取得するメソッド
  String getResultString() {
    String str = '';
    // オフセット定数
    int accXoffset = 5;
    int accYoffset = 7;
    int accZoffset = 9;
    int gyrXoffset = 11;
    int gyrYoffset = 13;
    int gyrZoffset = 15;
    int magXoffset = 17;
    int magYoffset = 19;
    int magZoffset = 21;

    // データの初期化
    String accX = "";
    String accY = "";
    String accZ = "";
    String gyrX = "";
    String gyrY = "";
    String gyrZ = "";
    String magX = "";
    String magY = "";
    String magZ = "";

    // データが存在する場合に処理を実行
    if (_data != null) {
      Uint8List data = _data!;
      // データバッチを作成（5つのデータポイント）
      for (int i = 0; i < 5; i++) {
        accX +=
            '${data[accXoffset + (i * 22)].toRadixString(16)}${data[accXoffset + 1 + (i * 22)].toRadixString(16)}';
        accY +=
            '${data[accYoffset + (i * 22)].toRadixString(16)}${data[accYoffset + 1 + (i * 22)].toRadixString(16)}';
        accZ +=
            '${data[accZoffset + (i * 22)].toRadixString(16)}${data[accZoffset + 1 + (i * 22)].toRadixString(16)}';
        gyrX +=
            '${data[gyrXoffset + (i * 22)].toRadixString(16)}${data[gyrXoffset + 1 + (i * 22)].toRadixString(16)}';
        gyrY +=
            '${data[gyrYoffset + (i * 22)].toRadixString(16)}${data[gyrYoffset + 1 + (i * 22)].toRadixString(16)}';
        gyrZ +=
            '${data[gyrZoffset + (i * 22)].toRadixString(16)}${data[gyrZoffset + 1 + (i * 22)].toRadixString(16)}';
        magX +=
            '${data[magXoffset + (i * 22)].toRadixString(16)}${data[magXoffset + 1 + (i * 22)].toRadixString(16)}';
        magY +=
            '${data[magYoffset + (i * 22)].toRadixString(16)}${data[magYoffset + 1 + (i * 22)].toRadixString(16)}';
        magZ +=
            '${data[gyrZoffset + (i * 22)].toRadixString(16)}${data[magZoffset + 1 + (i * 22)].toRadixString(16)}';
        if (i != 4) {
          accX += ',';
          accY += ',';
          accZ += ',';
          gyrX += ',';
          gyrY += ',';
          gyrZ += ',';
          magX += ',';
          magY += ',';
          magZ += ',';
        }
      }
      str += 'accX:' +
          accX +
          '\n' +
          'accY:' +
          accY +
          '\n' +
          'accZ:' +
          accZ +
          '\n' +
          'gyrX:' +
          gyrX +
          '\n' +
          'gyrY:' +
          gyrY +
          '\n' +
          'gyrZ:' +
          gyrZ +
          '\n' +
          'magX:' +
          magX +
          '\n' +
          'magY:' +
          magY +
          '\n' +
          'magZ:' +
          magZ;
    }
    return str;
  }

  // センサーの通知リスナーを追加するメソッド
  Future<bool> addNineAxisSensorNotificationListener() async {
    final res = await _samplePlugin.addNineAxisSensorNotificationListener(
        onStartNotification: _onStartNotification,
        onStopNotification: _onStopNotification,
        onReceiveNotification: _onReceiveNotification);
    return res;
  }

  // センサーの通知リスナーを削除するメソッド
  void _removeNineAxisSensorNotificationListener() {
    _samplePlugin.removeNineAxisSensorNotificationListener();
  }

  // 通知が開始されたときのコールバック
  void _onStartNotification(int resultCode) {
    _resultCode = resultCode;
    notifyListeners();
  }

  // 通知が停止されたときのコールバック
  void _onStopNotification(int resultCode) {
    _removeNineAxisSensorNotificationListener();
    _resultCode = resultCode;
    notifyListeners();
  }

  // 16進数の加速度データを変換するメソッド
  List<double> _convertHexToAccelerometerData(String hexString) {
    List<double> result = [];
    for (int i = 0; i < hexString.length; i += 4) {
      String hex = hexString.substring(i, i + 4);
      int value = int.parse(hex, radix: 16);
      if (value > 32767) value -= 65536; // 2の補数を考慮
      result.add(value / 1000); // 単位をgに変換
    }
    return result;
  }

  // 公開メソッドとして追加
  List<double> convertHexToAccelerometerData(String hexString) {
    return _convertHexToAccelerometerData(hexString);
  }

  // センサーデータを処理して頭の振りを検出するメソッド
  bool processSensorData(List<double> gyrXData, List<double> gyrYData,
      List<double> gyrZData, List<double> accYData, List<double> accZData) {
    print("processSensorData called"); // メソッドが呼び出されたことを確認

    print("gyrXData: $gyrXData"); // 各センサーデータの値を出力
    print("gyrYData: $gyrYData");
    print("gyrZData: $gyrZData");
    print("accYData: $accYData");
    print("accZData: $accZData");

    bool isShaking = _headShakeDetector.detectHorizontalHeadShake(
        gyrXData, gyrYData, gyrZData, accYData, accZData);

    print("isShaking: $isShaking"); // 頭振りが検出されたかどうかを出力

    return isShaking;
  } // センサーデータ受信時のコールバック

  void _onReceiveNotification(Uint8List? data, int resultCode) {
    _data = data;
    _resultCode = resultCode;
    List<String> hexData = getHexAccelDataBatch();
    List<double> accYData =
        _convertHexToAccelerometerData(hexData[1]); // accYのデータ
    List<double> accZData =
        _convertHexToAccelerometerData(hexData[2]); // accZのデータ
    List<double> gyrXData =
        _convertHexToAccelerometerData(hexData[3]); // gyrYのデータ

    List<double> gyrYData =
        _convertHexToAccelerometerData(hexData[4]); // gyrYのデータ
    List<double> gyrZData =
        _convertHexToAccelerometerData(hexData[5]); // gyrYのデータ

    bool isShaking =
        processSensorData(gyrXData, gyrYData, gyrZData, accYData, accZData);
    if (isShaking) {
      print("Horizontal head shake detected!"); // 頭の振りが検出された場合のログ



      ////////////////////////////////////////////////////////////////////////////////音鳴らす
       void startnineMusic() async {
        shouldContinue = true; // ループを継続する
        await audioPlayer.play('https://scrapbox.io/files/6686748da28f59001db76f16.wav');
        isPlaying = true;
      }
    }
    notifyListeners();
  }
}

class HeadShakeDetector {
  // ジャイロと加速度の閾値、および振りの検出間隔の定数
  final double _gyrMagnitudeThreshold = 700 / 1000; // ジャイロスコープの閾値
  final double _accMagnitudeThreshold = 2300 / 1000; // 加速度の閾値
  final double _accThreshold = 2000 / 1000;
  final int _minInterval = 5000; // 最小間隔（ミリ秒）
  final int _maxInterval = 9000; // 最大間隔（ミリ秒）

  // 振りのタイムスタンプを記録するリスト
  List<int> _shakeTimestamps = [];

  // 水平方向の頭の振りを検出するメソッド
  bool detectHorizontalHeadShake(List<double> gyrXData, List<double> gyrYData,
      List<double> gyrZData, List<double> accYData, List<double> accZData) {
    for (int i = 0; i < gyrYData.length; i++) {
      double gyrX = gyrXData[i].abs();
      double gyrY = gyrYData[i].abs();
      double gyrZ = gyrZData[i].abs();
      double accY = accYData[i].abs();
      double accZ = accZData[i].abs();

      double maccyz = (sqrt(accY * accY + accZ * accZ)).abs();
      double mgxyz = (sqrt(gyrX * gyrX + gyrY * gyrY + gyrZ * gyrZ)).abs();
      print("判定"); // メソッドが呼び出されたことを確認

      print("maccyz: $gyrX,基準:$_accMagnitudeThreshold"); // 各センサーデータの値を出力
      print("mgxyz: $gyrX,基準:$_gyrMagnitudeThreshold"); // 各センサーデータの値を出力
      print("accY: $accY,基準：$_accThreshold");
      print("accZ: $accZ,基準：$_accThreshold");

      // ジャイロまたは加速度が閾値を超える場合
      if ( //gyrY.abs() > _gyrThreshold ||
          //accY.abs() > _accThreshold ||
          //accZ.abs() > _accThreshold ||
          mgxyz.abs() > _gyrMagnitudeThreshold ||
              maccyz.abs() > _accMagnitudeThreshold) {
        // int currentTime = DateTime.now().millisecondsSinceEpoch;

        // // 閾値内のタイムスタンプを保持
        // _shakeTimestamps = _shakeTimestamps
        //     .where((timestamp) => currentTime - timestamp <= _maxInterval)
        //     .toList();

        // _shakeTimestamps.add(currentTime);

        // 一定数の振りが検出された場合
        // if (_shakeTimestamps.length >= 1) {
        //   int firstShake = _shakeTimestamps[_shakeTimestamps.length - 1];
        //   int lastShake = _shakeTimestamps.last;

        // // 最小・最大間隔内に1回の振りが検出された場合
        // if (lastShake - firstShake <= _maxInterval &&
        //     lastShake - firstShake >= _minInterval) {
        //   _shakeTimestamps.clear();
       void startnineMusic() async {
        shouldContinue = true; // ループを継続する
        await audioPlayer.play('https://scrapbox.io/files/6686748da28f59001db76f16.wav');
        print("aaaaaaaaaaaaaaaaaaaaaaaaaa");
        isPlaying = true;
      }
        return true; // 頭の振りが検出されたと判定
      }
    }
    return false; // 頭の振りが検出されなかった場合
  }
}
