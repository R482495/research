// added----------------------
import 'dart:io';
import 'package:audioplayers/audioplayers.dart'; 
// ---------------------------

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

//import 'package:hearable_device_sdk_sample/size_config.dart';
//import 'package:hearable_device_sdk_sample/widget_config.dart';
import 'package:hearable_device_sdk_sample/widgets.dart';
import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/nine_axis_sensor.dart';
import 'package:hearable_device_sdk_sample/temperature.dart';
import 'package:hearable_device_sdk_sample/heart_rate.dart';
import 'package:hearable_device_sdk_sample/ppg.dart';
import 'package:hearable_device_sdk_sample/eaa.dart';
import 'package:hearable_device_sdk_sample/battery.dart';
import 'package:hearable_device_sdk_sample/config.dart';

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

//add for time
import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:intl/intl.dart';

class HearableServiceView extends StatelessWidget {
  const HearableServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: NineAxisSensor()),
        ChangeNotifierProvider.value(value: Temperature()),
        ChangeNotifierProvider.value(value: HeartRate()),
        ChangeNotifierProvider.value(value: Ppg()),
        ChangeNotifierProvider.value(value: Eaa()),
        ChangeNotifierProvider.value(value: Battery()),
      ],
      child: _HearableServiceView(),
    );
  }
}

// オーディオソースのデータクラス//
  class AudioSource {//
    final String name;//
    final String url;//

  AudioSource({required this.name, required this.url});//
  }//

  // 音源リストと選択された音源
List<AudioSource> audioSources = [
  AudioSource(name: 'White Noise', url: 'https://scrapbox.io/files/6686748da28f59001db76f16.wav'),
  AudioSource(name: 'Pink Noise', url: 'https://scrapbox.io/files/66bdb88000d1dd001caac96a.wav'),
  AudioSource(name: 'Brown Noise', url: 'https://scrapbox.io/files/66bdb986a27a56001cdeec89.wav'),
];
AudioSource selectedAudioSource = audioSources[0];

class _HearableServiceView extends StatefulWidget {
  @override
  State<_HearableServiceView> createState() => _HearableServiceViewState();
}


class _HearableServiceViewState extends State<_HearableServiceView> {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
      HearableDeviceSdkSamplePlugin();
  String userUuid = (Eaa().featureGetCount == 0)
      ? const Uuid().v4()
      : Eaa().registeringUserUuid;
  var selectedIndex = -1;
  var selectedUser = '';
  bool isSetEaaCallback = false;

  final HeadShakeDetector _headShakeDetector = HeadShakeDetector();
  bool _isShakeDetected = false;
  //頭の振りリセット用
  Timer? _resetTimer;

  var config = Config();
  Eaa eaa = Eaa();
  late AudioPlayer audioPlayer;///////////////////////////////
  bool isPlaying = false; // 音楽が再生中かどうかを示す
  bool shouldContinue = true; // ループを制御する
  double volume = 0.5;
  bool isIncreasing = true;
  final double volumeStep = 0.05;//音量の上げていく量
  HeartRate heartRate = HeartRate(); ///////////////////////////



   // 音源リストと選択された音源////////////////////////////////////add814
  //List<String> audioSources = [
  // 'https://scrapbox.io/files/6686748da28f59001db76f16.wav',//White
  //  'https://scrapbox.io/files/66bdb88000d1dd001caac96a.wav',//Pink
  //  'https://scrapbox.io/files/66bdb986a27a56001cdeec89.wav',///Brown
  //];
  //String selectedAudioSource = 'https://scrapbox.io/files/6686748da28f59001db76f16.wav';///////

//add counter
int _count = 0;
double previousMgxyz = 0.0; // 直前の mgxyz 値
//

  TextEditingController featureRequiredNumController = TextEditingController();
  TextEditingController featureCountController = TextEditingController();
  TextEditingController eaaResultController = TextEditingController();

  TextEditingController nineAxisSensorResultController =
      TextEditingController();
  TextEditingController temperatureResultController = TextEditingController();
  TextEditingController heartRateResultController = TextEditingController();
  TextEditingController ppgResultController = TextEditingController();

  TextEditingController batteryIntervalController = TextEditingController();
  TextEditingController batteryResultController = TextEditingController();
  
  @override///////////////////////////////////////////////
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
     // HeartRateの通知リスナーを追加
    heartRate.addHeartRateNotificationListener();
  }

    @override///////////////////////////////
  void dispose() {
    shouldContinue = false; // ループを停止する
    heartRate.removeHeartRateNotificationListener();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> volumeAdjustment() async {
   int? bpm = heartRate.getBPM();
    if (bpm != null) {
      double interval = 60 / bpm * 1.05;
      while (shouldContinue) {
        // 音量を徐々に上げる
        while (isIncreasing && shouldContinue) {
          volume += volumeStep;//volumeにvolumeStepたしていく
          if (volume >= 1.0) {//1.0に達したらさげていく
            volume = 1.0;
            isIncreasing = false;
          }
          await audioPlayer.setVolume(volume);
          await Future.delayed(Duration(milliseconds: (interval * 1000 / (1 / volumeStep)).toInt()));
        }
      
        // 音量を徐々に下げる
        while (!isIncreasing && shouldContinue) {
          volume -= volumeStep;
          if (volume <= 0.5) {
            volume = 0.5;
            isIncreasing = true;
          }
          await audioPlayer.setVolume(volume);
          await Future.delayed(Duration(milliseconds: (interval * 1000 / (1 / volumeStep)).toInt()));
        }
      }
    }
  }  

  void startMusic() async {
    shouldContinue = true; // ループを継続する
    await audioPlayer.play(selectedAudioSource.url);//change814//////9.17
    volumeAdjustment(); // 音量調整を開始
    setState(() {
      isPlaying = true;
    });
  }

  void stopMusic() async {
    shouldContinue = false; // ループを停止する
    await audioPlayer.stop(); // 音楽を停止する
    _count = 0;
    setState(() {
      isPlaying = false;
    });
  }


  void _createUuid() {
    userUuid = const Uuid().v4();

    eaa.featureGetCount = 0;
    eaa.registeringUserUuid = userUuid;
    _samplePlugin.cancelEaaRegistration();

    setState(() {});
  }

  void _feature() async {
    eaa.registeringUserUuid = userUuid;
    _showDialog(context, '特徴量取得・登録中...');
    // 特徴量取得、登録
    if (!(await _samplePlugin.registerEaa(uuid: userUuid))) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _deleteRegistration() async {
    _showDialog(context, '登録削除中...');
    // ユーザー削除
    if (!(await _samplePlugin.deleteSpecifiedRegistration(
        uuid: selectedUser))) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _deleteAllRegistration() async {
    _showDialog(context, '登録削除中...');
    // ユーザー全削除
    if (!(await _samplePlugin.deleteAllRegistration())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _cancelRegistration() async {
    // 特徴量登録キャンセル
    if (!(await _samplePlugin.cancelEaaRegistration())) {
      // エラーダイアログ
      Alert.showAlert(context, 'IllegalStateException');
    }
  }

  void _verify() async {
    _showDialog(context, '照合中...');
    // 照合
    if (!(await _samplePlugin.verifyEaa())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _requestRegisterStatus() async {
    _showDialog(context, '登録状態取得中...');
    // 登録状態取得
    if (!(await _samplePlugin.requestRegisterStatus())) {
      Navigator.of(context).pop();
      // エラーダイアログ
      Alert.showAlert(context, 'Exception');
    }
  }

  void _switch9AxisSensor(bool enabled) async {
    NineAxisSensor().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await NineAxisSensor().addNineAxisSensorNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        NineAxisSensor().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    setState(() {});

    } else {
      // 取得終了
      if (!(await _samplePlugin.stopNineAxisSensorNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        NineAxisSensor().isEnabled = !enabled;
      }
    }
    // setState(() {});
  }

  void _switchTemperature(bool enabled) async {
    Temperature().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Temperature().addTemperatureNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Temperature().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startTemperatureNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Temperature().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopTemperatureNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Temperature().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchHeartRate(bool enabled) async {
    HeartRate().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await HeartRate().addHeartRateNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        HeartRate().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startHeartRateNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        HeartRate().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopHeartRateNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        HeartRate().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchPpg(bool enabled) async {
    Ppg().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Ppg().addPpgNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Ppg().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startPpgNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Ppg().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopPpgNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Ppg().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  void _switchBattery(bool enabled) async {
    Battery().isEnabled = enabled;
    if (enabled) {
      // callback登録
      if (!(await Battery().addBatteryNotificationListener())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalArgumentException');
        Battery().isEnabled = !enabled;
      }
      // 取得開始
      if (!(await _samplePlugin.startBatteryNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Battery().isEnabled = !enabled;
      }
    } else {
      // 取得終了
      if (!(await _samplePlugin.stopBatteryNotification())) {
        // エラーダイアログ
        Alert.showAlert(context, 'IllegalStateException');
        Battery().isEnabled = !enabled;
      }
    }
    setState(() {});
  }

  // 選択可能なListView
  ListView _createUserListView(BuildContext context) {
    return ListView.builder(
        // 登録ユーザー数
        itemCount: eaa.uuids.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              selected: selectedIndex == index ? true : false,
              selectedTileColor: Colors.grey.withOpacity(0.3),
              title: Widgets.uuidText(eaa.uuids[index]),
              onTap: () {
                if (index == selectedIndex) {
                  _resetSelection();
                } else {
                  selectedIndex = index;
                  selectedUser = eaa.uuids[index];
                }
                setState(() {});
              },
            ),
          );
        });
  }

  void _showDialog(BuildContext context, String text) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.blue.withOpacity(0.5),
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          return AlertDialog(
            content: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(text)
                  ],
                )
              ],
            ),
          );
        });
  }

  void _resetSelection() {
    selectedIndex = -1;
    selectedUser = '';
  }

  void _saveInput(BuildContext context) {
    var num = featureRequiredNumController.text;
    var interval = batteryIntervalController.text;

    if (num.isNotEmpty) {
      var num0 = int.parse(num);
      if (num0 >= 10 && num0 != config.featureRequiredNumber) {
        config.featureRequiredNumber = num0;
        _samplePlugin.setHearableEaaConfig(featureRequiredNumber: num0);
      }
    }
    _setRequiredNumText();

    if (interval.isNotEmpty) {
      var interval0 = int.parse(interval);
      if (interval0 >= 10 && interval0 != config.batteryNotificationInterval) {
        config.batteryNotificationInterval = interval0;
        _samplePlugin.setBatteryNotificationInterval(interval: interval0);
      }
    }
    _setBatteryIntervalText();

    setState(() {});
    FocusScope.of(context).unfocus();
  }

  void _onSavedFeatureRequiredNum(String? numStr) {
    if (numStr != null) {
      config.featureRequiredNumber = int.parse(numStr);
      _setRequiredNumText();
    }
    setState(() {});
  }

  void _onSavedBatteryInterval(String? intervalStr) {
    if (intervalStr != null) {
      config.batteryNotificationInterval = int.parse(intervalStr);
      _setBatteryIntervalText();
    }
    setState(() {});
  }

  void _setRequiredNumText() {
    featureRequiredNumController.text = config.featureRequiredNumber.toString();
    featureRequiredNumController.selection = TextSelection.fromPosition(
        TextPosition(offset: featureRequiredNumController.text.length));
  }

  void _setBatteryIntervalText() {
    batteryIntervalController.text =
        config.batteryNotificationInterval.toString();
    batteryIntervalController.selection = TextSelection.fromPosition(
        TextPosition(offset: batteryIntervalController.text.length));
  }

  void _registerCallback() {
    Navigator.of(context).pop();
  }

  void _deleteRegistrationCallback() {
    Navigator.of(context).pop();
    _resetSelection();
  }

  void __cancelRegistrationCallback() {
    eaa.featureGetCount = 0;
    setState(() {});
  }

  void _verifyCallback() {
    Navigator.of(context).pop();
  }

  void _getRegistrationStatusCallback() {
    Navigator.of(context).pop();
    _resetSelection();
  }

  // added----------------------------------------------------

  // csvファイルの中身となるリスト
  List<List<String>> accData = [
    ["time","ax", "ay", "az", "gx", "gy", "gz", "maccyz", "mgxyz"]
  ];

  void addAccelData(List<String> accelDataBatch) {
    // nine_axis_sensor.dartのgetHexAccelDataBatch()で作った文字列を分解し、5回分の加速度センサの値をリストに追加します。

    DateTime now = DateTime.now();
    if (accelDataBatch[0].length != (4 * 5)) return;

    for (int i = 0; i < 5; i++) {
      int ax = signedHex2Dec(accelDataBatch[0].substring(i * 4, i * 4 + 4));
      int ay = signedHex2Dec(accelDataBatch[1].substring(i * 4, i * 4 + 4));
      int az = signedHex2Dec(accelDataBatch[2].substring(i * 4, i * 4 + 4));
      int gx = signedHex2Dec(accelDataBatch[3].substring(i * 4, i * 4 + 4));
      int gy = signedHex2Dec(accelDataBatch[4].substring(i * 4, i * 4 + 4));
      int gz = signedHex2Dec(accelDataBatch[5].substring(i * 4, i * 4 + 4));
      //added--------------------
      double maccyz = sqrt(ax * ax + ay * ay + az * az);
      double mgxyz = sqrt(gx * gx + gy * gy + gz * gz);

      //--------------------------
      accData.add([
        DateFormat('yyyy_MM_dd(E) HH:mm:ss').format(DateTime.now()),
        ax.toString(),
        ay.toString(),
        az.toString(),
        gx.toString(),
        gy.toString(),
        gz.toString(),
        //added------------------
        maccyz.toString(),
        mgxyz.toString()
        
        //---------------------------
      ]);
 if (mgxyz >= 1000 && previousMgxyz < 1000) {
 _count++;
 if (_count > 3) {
      //setState(() {
        startMusic();
        _count = 0;
      //  }); 
           }
        }
  previousMgxyz = mgxyz;
    }
  }

  // ☆　csvファイルの中身となるリスト heartbeat 心拍
  List hrData = [
    ["time", "bpm"]
  ];

  void addhrData(String hrDataBatch) {
    // nine_axis_sensor.dartのgetHexAccelDataBatch()で作った文字列を分解し、5回分の加速度センサの値をリストに追加します。
    DateTime now = DateTime.now();
    hrData.add([
      DateFormat('yyyy_MM_dd(E) HH:mm:ss').format(DateTime.now()),
      hrDataBatch
    ]);
  }
  // ☆　csvファイルの中身となるリスト heartbeat 心拍　ここまで

  int signedHex2Dec(String signedHex) {
    // 符号付き16ビット16進数の文字列を、10進数に変換します。

    int intValue = int.parse(signedHex, radix: 16); // 16進数文字列をint型に変換

    // 符号付き16ビット整数として扱う場合、2の補数を用いて処理します
    if (intValue & (1 << 15) != 0) {
      // 最上位ビットが1の場合（負数の場合）
      intValue = intValue - (1 << 16); // 2の補数を使って負数に変換
    }

    return intValue;
  }

  Future<void> createAccCSV() async {
    // accDataをもとにcsvファイルを作ります。

    const path = "/storage/emulated/0/Download";
    DateTime now = DateTime.now();
    var file = File('$path/accdata' +
        DateFormat('yyyy_MM_dd(E) HH_mm').format(DateTime.now()) +
        '.csv');
    if (!await file.exists()) {
      await file.create();
    }
    var csvData = StringBuffer();
    for (var row in accData) {
      csvData.writeln(row.join(','));
    }
    await file.writeAsString(csvData.toString());
  }

// ☆　heart rate csv　ファイル作成
  Future<void> createHrCSV() async {
    // accDataをもとにcsvファイルを作ります。

    const path = "/storage/emulated/0/Download";
    DateTime now = DateTime.now();
    var file = File('$path/hrdata' +
        DateFormat('yyyy_MM_dd(E) HH_mm').format(DateTime.now()) +
        '.csv');
    if (!await file.exists()) {
      await file.create();
    }
    var csvData = StringBuffer();
    for (var row in hrData) {
      csvData.writeln(row.join(','));
    }
    await file.writeAsString(csvData.toString());
  }
// ☆　heart rate csv　ファイル作成 　ここまで

  // added----------------------------------------------------

  // 温度csvファイルの中身となるリスト
  List<List<String>> tempData = [
    ["time", "temp"]
  ];

  void addTempData(String tempDataBatch) {
    // nine_axis_sensor.dartのgetHexAccelDataBatch()で作った文字列を分解し、5回分の加速度センサの値をリストに追加します。
    DateTime now = DateTime.now();

    tempData.add([
      DateFormat('yyyy_MM_dd(E) HH:mm:ss').format(DateTime.now()),
      tempDataBatch,
    ]);
  }

  Future<void> createtempCSV() async {
    // accDataをもとにcsvファイルを作ります。

    const path = "/storage/emulated/0/Download";
    DateTime now = DateTime.now();
    var file = File('$path/tempData' +
        DateFormat('yyyy_MM_dd(E) HH_mm').format(DateTime.now()) +
        '.csv');
    if (!await file.exists()) {
      await file.create();
    }
    bool fileExists = await file.exists();
    if (fileExists) {
      print('CSVファイルが存在します: ${file.path}');
    } else {
      print('CSVファイルが存在しません');
    }

    var csvData = StringBuffer();
    for (var row in tempData) {
      csvData.writeln(row.join(','));
    }
    await file.writeAsString(csvData.toString());
  }

  // ---------------------------------------------------------
//頭の振りリセット用
  void _resetTripleShakeDetection() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _isShakeDetected = false;
        _count = 0; // カウントをリセット
      });
    });
  }

  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    _setRequiredNumText();
    _setBatteryIntervalText();

    if (!isSetEaaCallback) {
      eaa.addEaaListener(
          registerCallback: _registerCallback,
          cancelRegistrationCallback: null,
          deleteRegistrationCallback: _deleteRegistrationCallback,
          verifyCallback: _verifyCallback,
          getRegistrationStatusCallback: _getRegistrationStatusCallback);
      isSetEaaCallback = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('センサデータ確認', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {_saveInput(context)},
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,

              children: <Widget>[
                 if (_isShakeDetected)
                  const Text('頭振りを検出しました！',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255))),//////////////////////////////////////////////////////

                // added---------------------------------------------------------
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) {
                  if (nineAxisSensor.isEnabled) {
                    // 5回分の加速度センサを得る。
                    List<String> accelDataBatch =
                        nineAxisSensor.getHexAccelDataBatch();

                    // csv用のリストに追加する。
                    addAccelData(accelDataBatch);
                    // 頭振り検出の処理を更新
                    if (accelDataBatch.length >= 6) {
                      List<double> accYData = nineAxisSensor
                          .convertHexToAccelerometerData(accelDataBatch[1]);
                      List<double> accZData = nineAxisSensor
                          .convertHexToAccelerometerData(accelDataBatch[2]);
                      List<double> gyrXData = nineAxisSensor
                          .convertHexToAccelerometerData(accelDataBatch[3]);
                      List<double> gyrYData = nineAxisSensor
                          .convertHexToAccelerometerData(accelDataBatch[4]);
                      List<double> gyrZData = nineAxisSensor
                          .convertHexToAccelerometerData(accelDataBatch[5]);

                      bool isShaking = nineAxisSensor.processSensorData(
                          gyrXData, gyrYData, gyrZData, accYData, accZData);
                      if (isShaking && !_isShakeDetected) {

                      //  void Music2() async {
                      //    shouldContinue = true; // ループを継続する
                      //    await audioPlayer.play('https://scrapbox.io/files/6686748da28f59001db76f16.wav');

                          //setState(() {
                        //  isPlaying = true;
                          //});
                      //  }

                        setState(() {
                          _isShakeDetected = true;
                        });
                        // ここで2回の頭振りが検出された時のアクションを実行
                        // 2回の頭振りが検出された後にリセットタイマーを開始
                        //頭の振りリセット用
                        //startMusic();
                        _resetTripleShakeDetection();
                        //  音を鳴らす

                      //  void Music() async {
                      //    shouldContinue = true; // ループを継続する
                      //    await audioPlayer.play('https://scrapbox.io/files/6686748da28f59001db76f16.wav');

                      //    setState(() {
                      //    isPlaying = true;
                      //    });
                      //  }
                      }
                    }
                  }
                  // csvを作成するボタン
                  return ElevatedButton(
                    onPressed: () {
                      createAccCSV();
                    },
                    child: Text("加速度センサのcsvを作る(現在のデータ数：${accData.length - 1})"),
                  );
                })),
                // --------------------------------------------------------------
                Consumer<Temperature>(builder: ((context, temperature, _) {
                  if (temperature.isEnabled) {
                    // 5回分の温度センサを得る。
                    String tempDataBatch =
                        temperature.getTemperatureDataBatch();

                    // 温度csv用のリストに追加する。
                    addTempData(tempDataBatch);
                  }

                  // csvを作成するボタン
                  return ElevatedButton(
                    onPressed: () {
                      createtempCSV();
                    },
                    child: Text("温度のcsvを作る(現在のデータ数：${tempData.length - 1})"),
                  );
                })),

                // ☆　heart rate 　ファイル作成  ----------------------------------------------------
                Consumer<HeartRate>(builder: ((context, heartRate, _) {
                  if (heartRate.isEnabled) {
                    // 5回分の加速度センサを得る。
                    String hrDataBatch = heartRate.getHR();

                    // csv用のリストに追加する。
                    addhrData(hrDataBatch);
                  }
                  // csvを作成するボタン
                  return ElevatedButton(
                    onPressed: () {
                      createHrCSV();
                    },
                    child: Text("心拍のcsvを作る(現在のデータ数：${hrData.length - 1})"),
                  );
                })),
                // ☆　heart rate 　ファイル作成  ここまで
                // 音声再生ボタン///////////////////////////////////////
                //ElevatedButton(
                  //onPressed: () async {
                    //await audioPlayer.play(AssetSource('assets/audio/whitenoise.wav'));
                    //await audioPlayer.play('assets/audio/whitenoise.wav', isLocal: true);//audioplayers: ^0.20.1これに対して, isLocal: true古いバージョン
                    //await audioPlayer.play('https://scrapbox.io/files/6686748da28f59001db76f16.wav');
                  //},
                  //child: Text("音を鳴らす"),
                //),
                
                // 音源選択ドロップダウンメニュー///////////change814s
                DropdownButton<AudioSource>(
                  value: selectedAudioSource,
                  onChanged: (AudioSource? newValue) {
                    setState(() {
                      selectedAudioSource = newValue!;
                    });
                  },
                  items: audioSources.map<DropdownMenuItem<AudioSource>>((AudioSource source) {
                    return DropdownMenuItem<AudioSource>(
                      value: source,
                      child: Text(source.name),
                    );
                  }).toList(),
                ),

                ElevatedButton(
                  onPressed: isPlaying ? null : startMusic, // 音楽が再生中なら無効化
                  child: Text("noise creation"),
                ),
                ElevatedButton(
                  onPressed: isPlaying ? stopMusic : null, // 音楽が停止中なら無効化
                  child: Text("stop!!"),
                ),

                const SizedBox(height: 10),
                const Text('確認したいデータをOnにしてください',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                // 9軸センサ
                const SizedBox(
                  height: 20,
                ),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.switchContainer(
                            title: '9軸センサ',
                            enable: nineAxisSensor.isEnabled,
                            function: _switch9AxisSensor))),
                const SizedBox(height: 10),
                Consumer<NineAxisSensor>(
                    builder: ((context, nineAxisSensor, _) =>
                        Widgets.resultContainer(
                            verticalRatio: 40,
                            controller: nineAxisSensorResultController,
                            text: nineAxisSensor.getResultString()))),
                // if (_isShakeDetected)
                //   const Text('頭振りを検出しました！',
                //       style: TextStyle(
                //           fontWeight: FontWeight.bold, color: Colors.red)),

                const SizedBox(height: 20),
                // 温度
                Consumer<Temperature>(
                    builder: ((context, temperature, _) =>
                        Widgets.switchContainer(
                            title: '温度',
                            enable: temperature.isEnabled,
                            function: _switchTemperature))),
                const SizedBox(height: 10),
                Consumer<Temperature>(
                    builder: ((context, temperature, _) =>
                        Widgets.resultContainer2(
                            verticalRatio: 15,
                            controller: temperatureResultController,
                            text: temperature.getResultString()))),
                const SizedBox(height: 20),
                // 脈数
                Consumer<HeartRate>(
                    builder: ((context, heartRate, _) =>
                        Widgets.switchContainer(
                            title: '脈数',
                            enable: heartRate.isEnabled,
                            function: _switchHeartRate))),
                const SizedBox(height: 10),
                // Consumer<HeartRate>(
                //     builder: ((context, heartRate, _) =>
                //         Widgets.resultContainer2(
                //             verticalRatio: 18,
                //             controller: heartRateResultController,
                //             text: heartRate.getResultString()))),
                Consumer<HeartRate>(
                    builder: ((context, heartRate, _) =>
                        Widgets.resultContainer2(
                            verticalRatio: 18,
                            controller: heartRateResultController,
                            text: heartRate.getResultString()))),

                const SizedBox(height: 20),
                // 装着適正度
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.switchContainer(
                        title: '装着適正度',
                        enable: ppg.isEnabled,
                        function: _switchPpg))),
                const SizedBox(height: 10),
                Consumer<Ppg>(
                    builder: ((context, ppg, _) => Widgets.resultContainer3(
                        verticalRatio: 18,
                        controller: ppgResultController,
                        text: ppg.getResultString()))),
                const SizedBox(height: 20),
                // バッテリー情報取得間隔設定
                Widgets.inputNumberContainer(
                    title: 'バッテリー情報取得間隔設定',
                    unit: '秒',
                    horizontalRatio: 20,
                    controller: batteryIntervalController,
                    function: _onSavedBatteryInterval),
                const SizedBox(height: 10),
                Consumer<Battery>(
                    builder: ((context, battery, _) => Widgets.switchContainer(
                        title: 'バッテリー情報',
                        enable: battery.isEnabled,
                        function: _switchBattery))),
                const SizedBox(height: 10),
                Consumer<Battery>(
                    builder: ((context, battery, _) => Widgets.resultContainer2(
                        verticalRatio: 15,
                        controller: batteryResultController,
                        text: battery.getResultString()))),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
