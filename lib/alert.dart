import 'package:flutter/material.dart';

// Alert クラスを定義
class Alert {
  // 静的メソッド showAlert を定義
  // このメソッドはエラーダイアログを表示する
  static void showAlert(BuildContext context, String text) {
    // showDialog メソッドを使用してダイアログを表示
    showDialog(
      context: context, // ダイアログを表示するためのビルドコンテキストを指定
      builder: (_) {
        // AlertDialog ウィジェットを返す
        return AlertDialog(
          title: const Text("Error"), // ダイアログのタイトルを設定
          content: Text(text), // ダイアログの内容を設定
          actions: [
            // アクションボタンを設定
            TextButton(
              child: const Text('OK'), // ボタンのテキストを設定
              onPressed: () {
                // ボタンが押された時の処理を設定
                Navigator.pop(context); // ダイアログを閉じる
              },
            )
          ],
        );
      },
    );
  }
}
