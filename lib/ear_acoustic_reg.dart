import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUID生成のためのパッケージ
import 'package:provider/provider.dart'; // 状態管理のためのProviderパッケージ
import 'package:hearable_device_sdk_sample/size_config.dart'; // カスタムのサイズ設定
import 'package:hearable_device_sdk_sample/widget_config.dart'; // カスタムウィジェットの設定
import 'package:hearable_device_sdk_sample/widgets.dart'; // カスタムウィジェット
import 'package:hearable_device_sdk_sample/alert.dart'; // アラートダイアログのユーティリティ
import 'package:hearable_device_sdk_sample/nine_axis_sensor.dart'; // 9軸センサーの機能
import 'package:hearable_device_sdk_sample/temperature.dart'; // 温度機能
import 'package:hearable_device_sdk_sample/heart_rate.dart'; // 心拍数機能
import 'package:hearable_device_sdk_sample/ppg.dart'; // PPG（光電式脈波）機能
import 'package:hearable_device_sdk_sample/eaa.dart'; // 耳音響認証（EAA）機能
import 'package:hearable_device_sdk_sample/battery.dart'; // バッテリー機能
import 'package:hearable_device_sdk_sample/config.dart'; // アプリの設定

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart'; // ヒアラブルデバイスSDKプラグイン

// 耳音響認証画面のメインウィジェット
class EarAcoustic extends StatelessWidget {
  const EarAcoustic({super.key});

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
      child: _EarAcoustic(),
    );
  }
}

// 耳音響認証画面のプライベートウィジェット
class _EarAcoustic extends StatefulWidget {
  @override
  State<_EarAcoustic> createState() => _EarAcousticState();
}

// 耳音響認証画面の状態管理クラス
class _EarAcousticState extends State<_EarAcoustic> {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
  HearableDeviceSdkSamplePlugin(); // SDKプラグインのインスタンス
  String userUuid = (Eaa().featureGetCount == 0)
      ? const Uuid().v4()
      : Eaa().registeringUserUuid; // 条件に応じたUUID生成
  var selectedIndex = -1; // 選択されたユーザーのインデックス
  var selectedUser = ''; // 選択されたユーザーのUUID
  bool isSetEaaCallback = false; // EAAコールバック設定フラグ

  var config = Config(); // アプリの設定
  Eaa eaa = Eaa(); // EAAのインスタンス

  // テキスト入力用のコントローラー
  TextEditingController featureRequiredNumController =
  TextEditingController(); // 必要な機能数
  TextEditingController featureCountController = TextEditingController(); // 機能数
  TextEditingController eaaResultController = TextEditingController(); // EAA結果

  TextEditingController nineAxisSensorResultController =
  TextEditingController(); // 9軸センサー結果
  TextEditingController temperatureResultController =
  TextEditingController(); // 温度結果
  TextEditingController heartRateResultController =
  TextEditingController(); // 心拍数結果
  TextEditingController ppgResultController = TextEditingController(); // PPG結果

  TextEditingController batteryIntervalController =
  TextEditingController(); // バッテリー間隔
  TextEditingController batteryResultController =
  TextEditingController(); // バッテリー結果

  // UUIDを生成するメソッド
  void _createUuid() {
    userUuid = const Uuid().v4(); // 新しいUUIDを生成

    // EAA関連の状態をリセット
    eaa.featureGetCount = 0;
    eaa.registeringUserUuid = userUuid;
    _samplePlugin.cancelEaaRegistration(); // EAAの登録をキャンセル

    setState(() {}); // UIを更新
  }

  // 特徴量取得・登録を行うメソッド
  void _feature() async {
    eaa.registeringUserUuid = userUuid;
    _showDialog(context, '特徴量取得・登録中...'); // ダイアログを表示

    // 特徴量取得・登録の実行
    if (!(await _samplePlugin.registerEaa(uuid: userUuid))) {
      Navigator.of(context).pop(); // ダイアログを閉じる
      Alert.showAlert(context, 'Exception'); // エラーアラートを表示
    }
    setState(() {}); // UIを更新
  }

  // 特徴量登録をキャンセルするメソッド
  void _cancelRegistration() async {
    // 特徴量登録のキャンセル
    if (!(await _samplePlugin.cancelEaaRegistration())) {
      Alert.showAlert(context, 'IllegalStateException'); // エラーアラートを表示
    }
  }

  // 登録状態をリクエストするメソッド
  void _requestRegisterStatus() async {
    _showDialog(context, '登録状態取得中...'); // ダイアログを表示

    // 登録状態の取得
    if (!(await _samplePlugin.requestRegisterStatus())) {
      Alert.showAlert(context, 'Exception'); // エラーアラートを表示
    }
  }

  // ユーザーを選択可能なListViewを作成するメソッド
  ListView _createUserListView(BuildContext context) {
    return ListView.builder(
        itemCount: eaa.uuids.length, // 登録されているユーザー数
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              selected: selectedIndex == index ? true : false,
              selectedTileColor: Colors.grey.withOpacity(0.3),
              title: Widgets.uuidText(eaa.uuids[index]), // UUIDを表示するカスタムウィジェット
              onTap: () {
                if (index == selectedIndex) {
                  _resetSelection(); // 選択をリセット
                } else {
                  selectedIndex = index; // ユーザーを選択
                  selectedUser = eaa.uuids[index]; // 選択されたユーザーのUUIDを保持
                }
                setState(() {}); // UIを更新
              },
            ),
          );
        });
  }

  // ローディングダイアログを表示するメソッド
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

  // 選択をリセットするメソッド
  void _resetSelection() {
    selectedIndex = -1; // 選択を解除
    selectedUser = ''; // 選択されたユーザーをクリア
  }

  // ユーザーの入力を保存して設定を更新するメソッド
  void _saveInput(BuildContext context) {
    var num = featureRequiredNumController.text; // 必要な特徴量数の入力値
    var interval = batteryIntervalController.text; // バッテリーの通知間隔の入力値

    // 必要な特徴量数の設定
    if (num.isNotEmpty) {
      var num0 = int.parse(num);
      if (num0 >= 10 && num0 != config.featureRequiredNumber) {
        config.featureRequiredNumber = num0; // 設定を更新
        _samplePlugin.setHearableEaaConfig(featureRequiredNumber: num0); // SDKに設定を反映
      }
    }
    _setRequiredNumText(); // テキストフィールドを更新

    // バッテリーの通知間隔の設定
    if (interval.isNotEmpty) {
      var interval0 = int.parse(interval);
      if (interval0 >= 10 && interval0 != config.batteryNotificationInterval) {
        config.batteryNotificationInterval = interval0; // 設定を更新
        _samplePlugin.setBatteryNotificationInterval(interval: interval0); // SDKに設定を反映
      }
    }
    _setBatteryIntervalText(); // テキストフィールドを更新

    setState(() {}); // UIを更新
    FocusScope.of(context).unfocus(); // キーボードを非表示
  }

  // 必要な特徴量数のテキストフィールドを設定するメソッド
  void _onSavedFeatureRequiredNum(String? numStr) {
    if (numStr != null) {
      config.featureRequiredNumber = int.parse(numStr); // 設定を更新
      _setRequiredNumText(); // テキストフィールドを更新
    }
    setState(() {}); // UIを更新
  }

  // 必要な特徴量数のテキストフィールドを設定するメソッド
  void _setRequiredNumText() {
    featureRequiredNumController.text =
        config.featureRequiredNumber.toString(); // テキストフィールドに反映
    featureRequiredNumController.selection = TextSelection.fromPosition(
        TextPosition(offset: featureRequiredNumController.text.length)); // カーソルを末尾に移動
  }

  // バッテリーの通知間隔のテキストフィールドを設定するメソッド
  void _setBatteryIntervalText() {
    batteryIntervalController.text =
        config.batteryNotificationInterval.toString(); // テキストフィールドに反映
    batteryIntervalController.selection = TextSelection.fromPosition(
        TextPosition(offset: batteryIntervalController.text.length)); // カーソルを末尾に移動
  }

  // 登録コールバック
  void _registerCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  // 登録削除コールバック
  void _deleteRegistrationCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
    _resetSelection(); // 選択をリセット
  }

  // 検証コールバック
  void _verifyCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  // 登録状態取得コールバック
  void _getRegistrationStatusCallback() {
    Navigator.of(context).pop(); // ダイアログを閉じる
    _resetSelection(); // 選択をリセット
  }

  @override
  Widget build(BuildContext context) {
    _setRequiredNumText(); // 初期の必要数テキストを設定
    _setBatteryIntervalText(); // 初期のバッテリー間隔テキストを設定

    if (!isSetEaaCallback) {
      // EAAコールバックが未設定の場合
      eaa.addEaaListener(
          registerCallback: _registerCallback,
          cancelRegistrationCallback: null,
          deleteRegistrationCallback: _deleteRegistrationCallback,
          verifyCallback: _verifyCallback,
          getRegistrationStatusCallback: _getRegistrationStatusCallback);
      isSetEaaCallback = true; // 設定済みフラグを立てる
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('耳音響認証の特徴量登録', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {_saveInput(context)}, // 画面タップで入力を保存
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
                    '<Step:1>\n"UUID生成"ボタンをタップし、ユーザUUIDを生成します。',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  // UUID生成ボタン
                  child: ElevatedButton(
                    onPressed: _createUuid,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        backgroundColor: Colors.blue),
                    child: const Text(
                      'UUID生成',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    'ユーザUUID：$userUuid',
                    style: WidgetConfig.uuidTextStyle,
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '<Step:2>\n"登録状態"ボタンをタップして、ヒアラブルデバイスに保存されているユーザUUIDを確認します。\n※初期値は全て0です。UUIDは2つまで保存可能。',
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
                      '登録状態',
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
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '<Step:3>\n上に表示されたユーザUUIDのどちらかをタップで選択し、文字の色が変わったことを確認したら、"特徴量取得＆登録"ボタンをタップして、耳音響認証に必要な特徴量取得を行います。必要数が登録されるまでヒアラブルデバイスの装着・脱着を繰り返してください。最低20個の特徴量が必要です。\n※result codeが"0"になるまで繰り返します。',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),

                // 特徴量取得・登録、キャンセルボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      // 取得・登録ボタン
                      child: ElevatedButton(
                        onPressed: _feature,
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                            backgroundColor: Colors.indigo),
                        child: const Text(
                          '特徴量取得＆登録',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 160,
                      // 登録キャンセルボタン
                      child: ElevatedButton(
                        onPressed: _cancelRegistration,
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                            backgroundColor: Colors.redAccent),
                        child: const Text(
                          '登録キャンセル',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                Consumer<Eaa>(
                    builder: ((context, eaa, _) => Widgets.resultContainer(
                        verticalRatio: 25,
                        controller: eaaResultController,
                        text: eaa.resultStr))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        '特徴量取得試行回数',
                        style: WidgetConfig.boldTextStyle,
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Consumer<Eaa>(
                            builder: ((context, eaa, _) =>
                                Text('${eaa.featureGetCount} 回'))))
                  ],
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '初期値の変更：\n特徴量の取得必要数を設定できます。(最低20個)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                // 特徴量取得必要回数の入力フィールド
                Widgets.inputNumberContainer(
                    title: '特徴量取得必要回数',
                    unit: '回',
                    horizontalRatio: 15,
                    controller: featureRequiredNumController,
                    function: _onSavedFeatureRequiredNum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
