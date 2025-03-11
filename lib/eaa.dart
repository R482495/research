import 'package:flutter/foundation.dart'; // Flutterのfoundationパッケージをインポート

import 'package:hearable_device_sdk_sample_plugin/hearable_device_sdk_sample_plugin.dart'; // HearableデバイスSDKのサンプルプラグインをインポート

class Eaa extends ChangeNotifier {
  final HearableDeviceSdkSamplePlugin _samplePlugin =
  HearableDeviceSdkSamplePlugin(); // HearableデバイスSDKのサンプルプラグインのインスタンスを作成

  int featureGetCount = 0; // 特定の機能を取得した回数をカウントする変数
  String registeringUserUuid = ''; // 登録中のユーザーのUUID

  int? _resultCode = 0; // 操作の結果コードを格納する変数（初期値は0）
  double? _score; // スコアを格納する変数
  String? _uuid; // UUIDを格納する変数
  List<String> _uuids = []; // 複数のUUIDを格納するリスト

  String _resultStr = ''; // 結果を表す文字列

  // コールバック関数を保持する変数
  Function()? _registerCallback;
  Function()? _cancelRegistrationCallback;
  Function()? _deleteRegistrationCallback;
  Function()? _verifyCallback;
  Function()? _getRegistrationStatusCallback;

  static final Eaa _instance = Eaa._internal(); // Eaaクラスのシングルトンインスタンスを作成

  factory Eaa() {
    return _instance; // シングルトンインスタンスを返すファクトリコンストラクタ
  }

  Eaa._internal(); // シングルトンインスタンスを作成する内部コンストラクタ

  int? get resultCode => _resultCode; // _resultCodeのゲッター
  double? get score => _score; // _scoreのゲッター
  String? get uuid => _uuid; // _uuidのゲッター
  List<String> get uuids => _uuids; // _uuidsのゲッター

  String get resultStr => _resultStr; // _resultStrのゲッター

  // 結果を表す文字列を生成するメソッド
  void createResultString(
      int? resultCode, double? score, String? uuid, List<String>? uuids) {
    _resultStr = '';

    if (_resultCode != null) {
      _resultStr += 'result code: $_resultCode\n'; // 結果コードを文字列に追加
    }

    if (score != null) {
      _resultStr += 'score: $score\n'; // スコアを文字列に追加
    }

    if (uuid != null) {
      _resultStr += 'uuid: $uuid\n'; // UUIDを文字列に追加
    }

    if (uuids != null) {
      _resultStr += 'uuid:\n';
      for (var uuid in uuids) {
        _resultStr += '$uuid\n'; // 複数のUUIDを文字列に追加
      }
    }

    notifyListeners(); // リスナーに変更を通知
  }

  // Eaaリスナーを追加するメソッド
  Future<bool> addEaaListener({
    required Function()? registerCallback,
    required Function()? cancelRegistrationCallback,
    required Function()? deleteRegistrationCallback,
    required Function()? verifyCallback,
    required Function()? getRegistrationStatusCallback,
  }) async {
    _registerCallback = registerCallback;
    _cancelRegistrationCallback = cancelRegistrationCallback;
    _deleteRegistrationCallback = deleteRegistrationCallback;
    _verifyCallback = verifyCallback;
    _getRegistrationStatusCallback = getRegistrationStatusCallback;

    // HearableデバイスSDKのEaaリスナーを追加する
    final res = await _samplePlugin.addEaaListener(
        onRegister: _onRegister,
        onCancelRegistration: _onCancelRegistration,
        onDeleteRegistration: _onDeleteRegistration,
        onVerify: _onVerify,
        onGetRegistrationStatus: _onGetRegistrationStatus);

    if (!res) {
      print('addEaaListener: IllegalArgumentException');
    }

    return res; // リスナー追加の結果を返す
  }

  // Eaaリスナーを削除するメソッド
  void removeEaaListener() {
    _samplePlugin.removeEaaListener();
  }

  // 登録時に呼び出されるコールバック
  void _onRegister(int resultCode) {
    _resultCode = resultCode;
    createResultString(resultCode, null, null, null);

    // 特定の結果コードに応じて特定の処理を行う
    if (resultCode == 0 || resultCode == -200 || resultCode == -203) {
      featureGetCount++;
    }

    if (_registerCallback != null) {
      _registerCallback!();
    }

    notifyListeners(); // リスナーに変更を通知
  }

  // 登録キャンセル時に呼び出されるコールバック
  void _onCancelRegistration(int resultCode) {
    _resultCode = resultCode;
    createResultString(resultCode, null, null, null);
    if (_cancelRegistrationCallback != null) {
      _cancelRegistrationCallback!();
    }
    featureGetCount = 0;
    notifyListeners(); // リスナーに変更を通知
  }

  // 登録削除時に呼び出されるコールバック
  void _onDeleteRegistration(int resultCode) {
    _resultCode = resultCode;
    createResultString(resultCode, null, null, null);
    if (_deleteRegistrationCallback != null) {
      _deleteRegistrationCallback!();
    }
    notifyListeners(); // リスナーに変更を通知
  }

  // 認証結果取得時に呼び出されるコールバック
  void _onVerify(double? score, String? uuid, int resultCode) {
    if (resultCode == 0 && score != null && uuid != null) {
      _score = score;
      _uuid = uuid;
    }

    _resultCode = resultCode;
    createResultString(resultCode, score, uuid, null);
    if (_verifyCallback != null) {
      _verifyCallback!();
    }
    notifyListeners(); // リスナーに変更を通知
  }

  // 登録ステータス取得時に呼び出されるコールバック
  void _onGetRegistrationStatus(List<String>? uuids, int resultCode) {
    if (resultCode == 0 && uuids != null) {
      _uuids = uuids;
    }

    _resultCode = resultCode;
    createResultString(resultCode, null, null, uuids);
    if (_getRegistrationStatusCallback != null) {
      _getRegistrationStatusCallback!();
    }
    notifyListeners(); // リスナーに変更を通知
  }
}
