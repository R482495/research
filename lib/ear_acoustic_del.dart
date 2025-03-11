import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUIDパッケージ（ユニークな識別子を生成するため）
import 'package:provider/provider.dart'; // 状態管理のためのProviderパッケージ
import 'package:hearable_device_sdk_sample/size_config.dart'; // カスタムのサイズ設定
import 'package:hearable_device_sdk_sample/widget_config.dart'; // カスタムウィジェットの設定
import 'package:hearable_device_sdk_sample/widgets.dart'; // カスタムウィジェット
import 'package:hearable_device_sdk_sample/alert.dart'; // アラートダイアログユーティリティ
import 'package:hearable_device_sdk_sample/nine_axis_sensor.dart'; // 9軸センサー機能
import 'package:hearable_device_sdk_sample/temperature.dart'; // 温度機能
import 'package:hearable_device_sdk_sample/heart_rate.dart'; // 心拍数機能
import 'package:hearable_device_sdk_sample/ppg.dart'; // PPG（光電式脈波）機能
import 'package:hearable_device_sdk_sample/eaa.dart'; // 耳音響認証（EAA）機能
import 'package:hearable_device_sdk_sample/battery.dart'; // バッテリー機能
import 'package:hearable_device_sdk_sample/config.dart'; // 設定

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart'; // ヒアラブルデバイスSDKプラグイン

// 耳音響認証削除画面のメインウィジェット
class EarAcousticDel extends StatelessWidget {
  const EarAcousticDel({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 各種センサーおよび機能の状態管理プロバイダー
        ChangeNotifierProvider.value(value: NineAxisSensor()),
        ChangeNotifierProvider.value(value: Temperature()),
        ChangeNotifierProvider.value(value: HeartRate()),
        ChangeNotifierProvider.value(value: Ppg()),
        ChangeNotifierProvider.value(value: Eaa()),
        ChangeNotifierProvider.value(value: Battery()),
      ],
      child: _EarAcousticDel(),
    );
  }
}

// 耳音響認証削除画面のプライベートウィジェット
class _EarAcousticDel extends StatefulWidget {
  @override
  State<_EarAcousticDel> createState() => _EarAcousticDelState();
}

// 耳音響認証削除画面の状態管理クラス
class _EarAcousticDelState extends State<_EarAcousticDel> {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
  HearableDeviceSdkSamplePlugin(); // SDKプラグインのインスタンス
  String userUuid = (Eaa().featureGetCount == 0)
      ? const Uuid().v4()
      : Eaa().registeringUserUuid; // 条件付きUUID生成
  var selectedIndex = -1; // 選択されたユーザーのインデックス
  var selectedUser = ''; // 選択されたユーザーのUUID
  bool isSetEaaCallback = false; // EAAコールバック設定フラグ

  var config = Config(); // 設定のインスタンス
  Eaa eaa = Eaa(); // EAAのインスタンス

  TextEditingController featureRequiredNumController =
  TextEditingController(); // 機能必要数の入力コントローラー
  TextEditingController featureCountController =
  TextEditingController(); // 機能数の入力コントローラー
  TextEditingController eaaResultController =
  TextEditingController(); // EAA結果の入力コントローラー

  TextEditingController nineAxisSensorResultController =
  TextEditingController(); // 9軸センサーの結果の入力コントローラー
  TextEditingController temperatureResultController =
  TextEditingController(); // 温度の結果の入力コントローラー
  TextEditingController heartRateResultController =
  TextEditingController(); // 心拍数の結果の入力コントローラー
  TextEditingController ppgResultController =
  TextEditingController(); // PPGの結果の入力コントローラー

  TextEditingController batteryIntervalController =
  TextEditingController(); // バッテリー間隔の入力コントローラー
  TextEditingController batteryResultController =
  TextEditingController(); // バッテリー結果の入力コントローラー

  // ユーザー登録の削除を行うメソッド
  void _deleteRegistration() async {
    _showDialog(context, '登録削除中...');
    // ユーザー登録を削除
    if (!(await _samplePlugin.deleteSpecifiedRegistration(uuid: selectedUser))) {
      Navigator.of(context).pop();
      // エラーアラートダイアログを表示
      Alert.showAlert(context, 'Exception');
    }
  }

  // 全ての登録を削除するメソッド
  void _deleteAllRegistration() async {
    _showDialog(context, '登録削除中...');
    // 全てのユーザー登録を削除
    if (!(await _samplePlugin.deleteAllRegistration())) {
      Navigator.of(context).pop();
      // エラーアラートダイアログを表示
      Alert.showAlert(context, 'Exception');
    }
  }

  // 登録状態をリクエストするメソッド
  void _requestRegisterStatus() async {
    _showDialog(context, '登録状態取得中...');
    // 登録状態をリクエスト
    if (!(await _samplePlugin.requestRegisterStatus())) {
      // エラーアラートダイアログを表示
      Alert.showAlert(context, 'Exception');
    }
  }

  // 選択可能なListViewを作成するメソッド
  ListView _createUserListView(BuildContext context) {
    return ListView.builder(
        itemCount: eaa.uuids.length, // 登録されているユーザー数
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              selected: selectedIndex == index ? true : false,
              selectedTileColor: Colors.grey.withOpacity(0.3),
              title: Widgets.uuidText(eaa.uuids[index]), // UUIDテキストを表示
              onTap: () {
                if (index == selectedIndex) {
                  _resetSelection(); // すでに選択されている場合は選択を解除
                } else {
                  selectedIndex = index; // ユーザーを選択
                  selectedUser = eaa.uuids[index]; // 選択されたユーザーのUUIDを設定
                }
                setState(() {}); // UIを更新
              },
            ),
          );
        });
  }

  // ローディングインジケーター付きのダイアログを表示するメソッド
  void _showDialog(BuildContext context, String text) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
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

  // ユーザー選択をリセットするメソッド
  void _resetSelection() {
    selectedIndex = -1; // インデックスをリセット
    selectedUser = ''; // 選択されたユーザーをリセット
  }

  // ユーザー入力を保存し、設定を更新するメソッド
  void _saveInput(BuildContext context) {
    var num = featureRequiredNumController.text; // 必要な機能数を取得
    var interval = batteryIntervalController.text; // バッテリー間隔を取得

    if (num.isNotEmpty) {
      var num0 = int.parse(num);
      if (num0 >= 10 && num0 != config.featureRequiredNumber) {
        config.featureRequiredNumber = num0;
        _samplePlugin.setHearableEaaConfig(featureRequiredNumber: num0);
      }
    }
    _setRequiredNumText(); // 必要な数のテキストを更新

    if (interval.isNotEmpty) {
      var interval0 = int.parse(interval);
      if (interval0 >= 10 &&
          interval0 != config.batteryNotificationInterval) {
        config.batteryNotificationInterval = interval0;
        _samplePlugin.setBatteryNotificationInterval(interval: interval0);
      }
    }
    _setBatteryIntervalText(); // バッテリー間隔のテキストを更新

    setState(() {}); // UIを更新
    FocusScope.of(context).unfocus(); // キーボードを非表示にする
  }

  // 必要な数のテキストを設定するメソッド
  void _setRequiredNumText() {
    featureRequiredNumController.text =
        config.featureRequiredNumber.toString();
    featureRequiredNumController.selection = TextSelection.fromPosition(
        TextPosition(offset: featureRequiredNumController.text.length));
  }

  // バッテリー間隔のテキストを設定するメソッド
  void _setBatteryIntervalText() {
    batteryIntervalController.text =
        config.batteryNotificationInterval.toString();
    batteryIntervalController.selection = TextSelection.fromPosition(
        TextPosition(offset: batteryIntervalController.text.length));
  }

  // コールバックを登録するメソッド
  void _registerCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  // 登録削除コールバック用のメソッド
  void _deleteRegistrationCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
    _resetSelection(); // 選択をリセット
  }

  // 検証のためのコールバックメソッド
  void _verifyCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  // 登録状態取得用のコールバックメソッド
  void _getRegistrationStatusCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
    _resetSelection(); // 選択をリセット
  }

  @override
  Widget build(BuildContext context) {
    _setRequiredNumText(); // 初期の必要数テキストを設定
    _setBatteryIntervalText(); // 初期のバッテリー間隔テキストを設定

    if (!isSetEaaCallback) {
      // コールバックが設定されていない場合、EAAリスナーを追加
      eaa.addEaaListener(
          registerCallback: _registerCallback,
          cancelRegistrationCallback: null,
          deleteRegistrationCallback: _deleteRegistrationCallback,
          verifyCallback: _verifyCallback,
          getRegistrationStatusCallback: _getRegistrationStatusCallback);
      isSetEaaCallback = true; // コールバック設定フラグを更新
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザUUIDの削除', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTap: () => {_saveInput(context)},
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '<Step:1>\n"登録情報確認"ボタンをタップして、ヒアラブルデバイスに保存されているユーザUUIDを表示します。',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: _requestRegisterStatus,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        backgroundColor: Colors.blue),
                    child: const Text(
                      '登録情報確認',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: const Center(
                    child: Text(
                      'ヒアラブルデバイスに保存されているユーザUUID',
                      style: WidgetConfig.boldTextStyle,
                    ),
                  ),
                ),
                SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 85,
                    height: SizeConfig.blockSizeVertical * 20,
                    child: Consumer<Eaa>(
                        builder: ((context, eaa, _) =>
                            _createUserListView(context)))),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '<Step:2>\n上に表示された削除を行いたいUUIDをタップで選択し、文字の色が変わったことを確認したら、"ユーザUUID削除"ボタンをタップして削除します。',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: SizeConfig.blockSizeHorizontal * 40,
                  child: ElevatedButton(
                    onPressed: _deleteRegistration,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        backgroundColor: Colors.redAccent),
                    child: const Text(
                      'ユーザUUID削除',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '<補足>\n"ユーザUUIDの初期化"ボタンをタップしてまとめて削除もできます。',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: SizeConfig.blockSizeHorizontal * 40,
                  child: ElevatedButton(
                    onPressed: _deleteAllRegistration,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        backgroundColor: Colors.redAccent),
                    child: const Text(
                      'ユーザUUIDの初期化',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
