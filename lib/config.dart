class Config {
  int featureRequiredNumber = 20; // 特定の機能で必要な数値のデフォルト値
  int batteryNotificationInterval = 300; // バッテリ通知の間隔のデフォルト値（秒単位）

  static final Config _instance = Config._internal(); // Configクラスのシングルトンインスタンスを作成

  factory Config() {
    return _instance; // シングルトンインスタンスを返すファクトリコンストラクタ
  }

  Config._internal() {
    // アプリにデータを保存する場合はここで読み込みを行う
    // 例：ローカルストレージやデータベースから設定値を読み込む処理を追加することができます
  }
}
