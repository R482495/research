import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearable_device_sdk_sample/start_scan.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:hearable_device_sdk_sample/config.dart';
import 'package:hearable_device_sdk_sample/alert.dart';
import 'package:hearable_device_sdk_sample/result_message.dart';
import 'package:hearable_device_sdk_sample/bluetooth_manager.dart';
import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart';

//main関数
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutterエンジンの初期化を保証する
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); // デバイスの向きを縦方向に固定する
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false, // デバッグモードバナーを非表示にする//DEBUGボタンの非表示
    title: 'Sleep Support System',
    //title: 'へアラブルデバイス機能テストアプリ',
    // アプリ全体のタイトルを設定する
    home: const StartScreen(), // アプリのホーム画面を設定する
    theme: ThemeData(appBarTheme: const AppBarTheme(color: Colors.blue)), // アプリのテーマを設定する

  ));
}

//StartScreenクラスでUI（StatelessWidget）を継承してる
//スタート画面の構築
class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //MultiProvider: プロバイダーパッケージを使用して、依存関係の注入と状態管理を行い、BluetoothManagerをアプリケーション全体に提供する
    return MultiProvider(
      providers: [
        //BluetoothManagerのインスタンスをChangeNotifierProvider(状態管理を行う：状態を保持し、その状態が変更されたことをリスナーに通知する)を通じて提供しています。
        ChangeNotifierProvider.value(value: BluetoothManager()), // BluetoothManagerのインスタンスをプロバイダに登録
      ],
      //早速始めるボタンを押した後の画面のウィジェット(上のタイトルバー)
      //child: const _StartScreen(title: 'ヒアラブルデバイスに接続しましょう'),
      // child:MultiProviderの子として_StartScreenを設定していて、これより_StartScreen内でBluetoothManagerを利用できる
      child: const _StartScreen(title: '良い眠りへようこそ'), // _StartScreenウィジェットを提供
    );
  }
}
//スタート画面の内容を制御
class _StartScreen extends StatefulWidget {
  const _StartScreen({required this.title});
  //titleを受け取る
  final String title;
  @override
  //createStateメソッドでStatefulWidgetのサブクラスである _StartScreen のインスタンスに対して、対応する State オブジェクトである _StartScreenState のインスタンス
  State<_StartScreen> createState() => _StartScreenState(); // Stateオブジェクトを作成
}

//_StartScreenStateクラスがStateを管理し、その中で実際の処理が行われる
class _StartScreenState extends State<_StartScreen> {
  //HearableDeviceSdkSamplePluginのインスタンスを作成
  final HearableDeviceSdkSamplePlugin _samplePlugin = HearableDeviceSdkSamplePlugin(); // プラグインのインスタンスを作成
  //BluetoothManagerのインスタンスを作成
  final BluetoothManager _bluetoothManager = BluetoothManager(); // BluetoothManagerのインスタンスを作成

  // ヒアラブルデバイスサービスを開始するメソッド
  void _startService() async {
    // プラットフォームがAndroidの場合とそれ以外の場合でサービスを開始する方法を分ける
    Platform.isAndroid
        ? _samplePlugin.startService()
        : await _samplePlugin.startService();
//？？？？
    // Bluetooth接続リスナーの追加
    bool res = await _bluetoothManager.addHearableBleListener(
        connectCallback: _connectCallback, // 接続コールバックこの時にresultcodeが引数として渡されてる
        disconnectCallback: _disconnectCallback, // 切断コールバック
        scanCallback: _scanCallback); // スキャンコールバック

    // ヒアラブルデバイスのステータスリスナーを登録
    res = await _bluetoothManager.registHearableStatusListener();

    // ヒアラブルデバイスのEAA設定を行う
    //resの上書きしないと同時に接続、切断などの命令が通ってしまう
    res = await _samplePlugin.setHearableEaaConfig(
        featureRequiredNumber: Config().featureRequiredNumber);

    // バッテリ通知のインターバルを設定
    res = await _samplePlugin.setBatteryNotificationInterval(
        interval: Config().batteryNotificationInterval);

    // 設定が成功しなかった場合、エラーダイアログを表示
    if (!res) {
      Alert.showAlert(context, 'IllegalArgumentException');
    }
  }


  // 接続コールバックメソッド
  void _connectCallback(int resultCode) {
    Navigator.of(context).pop(); // ダイアログを閉じる
    //ユーザーがデバイスの接続操作を行った際に表示されていたダイアログが閉じられる
    if (resultCode != 0) { // エラーが発生した場合
      Alert.showAlert(context, ResultMessage.fromCode(resultCode).message); // エラーメッセージを表示
    }
  }

  // 切断コールバックメソッド
  void _disconnectCallback(int resultCode) {
    if (resultCode != 0) { // エラーが発生した場合
      Alert.showAlert(context, ResultMessage.fromCode(resultCode).message); // エラーメッセージを表示
    }
  }

  // スキャンコールバックメソッド
  void _scanCallback(int resultCode) {
    Navigator.of(context).pop(); // ダイアログを閉じる
    if (resultCode != 0) { // エラーが発生した場合
      Alert.showAlert(context, ResultMessage.fromCode(resultCode).message); // エラーメッセージを表示
    }
  }

  @override
  Widget build(BuildContext context) {
    //Scaffoldを使って画面の基本的な構造を作り
    return Scaffold(
      backgroundColor: Colors.white, // 背景色を白に設定
      //AppBarにはアプリのタイトルを設定し、背景色を
      appBar: AppBar(
        backgroundColor: Colors.blue, // AppBarの背景色を黒に設定
        centerTitle: true, // タイトルを中央に配置
        title: const Text(
          //最初の画面の上のタイトルバーのタイトル(?)
          'Sleep Support System', // AppBarのタイトル
          style: TextStyle(fontSize: 16),
        ),
      ),
      //bodyには画像、テキスト、ボタンなどを含む中央寄せのコンテンツを設定
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを中央に配置
          children: [
            Image.asset('assets/hearable.jpg'), // 画像を表示
            const Text(
              //最初の画面の中央のテキスト
              //'このサンプルアプリについて', // 説明テキスト
              'SSSアプリについて',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5), // 少しの余白を追加
            const Text('あなたもSSSの睡眠を手に入れませんか？！'), // 説明テキスト
            const SizedBox(height: 80), // 余白を追加
            TextButton(
              onPressed: () {
                _startService(); // サービスを開始
                //新しい画面に遷移する
                // Navigator.of(context).push(...)が呼び出され、新しいページルートがスタックに追加され、ユーザーが前画面に戻ることができる
                Navigator.of(context).push(
//???
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const StartScan(title: '接続開始'); // 新しい画面に遷移 // 遷移先のウィジェットを指定
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      //遷移アニメーションの設定
                      const Offset begin = Offset(1.0, 0.0); // 右から左への遷移
                      const Offset end = Offset.zero;
                      final Animatable<Offset> tween =
                      Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                      final Animation<Offset> offsetAnimation = animation.drive(tween);
                      // SlideTransitionを使ってアニメーションを適用する
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: const Text(
                //'早速始める', // ボタンテキスト
                '眠い。。。。',
                style: TextStyle(fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
