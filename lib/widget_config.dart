import 'package:flutter/material.dart';

class WidgetConfig {
  // アプリ全体で使用するテキストスタイルや装飾を定義する静的クラス

  // バータイトルのテキストスタイル
  static const TextStyle barTitleTextStyle = TextStyle(
    color: Colors.black, // テキストカラーを黒に設定
    fontSize: 16, // フォントサイズを16に設定
    fontWeight: FontWeight.bold, // フォントの太さを太字に設定
  );

  // ボタンのスタイル
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color.fromRGBO(220, 220, 220, 1.0), // 背景色を薄いグレーに設定
    foregroundColor: Colors.grey, // テキストの色をグレーに設定
    elevation: 0, // ボタンの影を無効に設定
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0.0), // ボタンの角を丸くしない
    ),
  );

  // ボタンのテキストスタイル
  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.black, // テキストカラーを黒に設定
    height: 1.0, // 行の高さを1.0に設定
  );

  // 太字のテキストスタイル
  static const TextStyle boldTextStyle = TextStyle(
    height: 1.0, // 行の高さを1.0に設定
    fontWeight: FontWeight.bold, // フォントの太さを太字に設定
  );

  // UUIDテキストのスタイル
  static const TextStyle uuidTextStyle = TextStyle(
    fontSize: 12, // フォントサイズを12に設定
    fontWeight: FontWeight.bold, // フォントの太さを太字に設定
  );

  // 数値入力フィールドのデコレーション（枠線なし）
  static const InputDecoration featureRequiredNumberInputDecoration = InputDecoration(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        width: 0, // 枠線の幅を0に設定
        style: BorderStyle.none, // 枠線なし
      ),
    ),
  );

  // テキスト入力フィールドのデコレーション
  static Decoration inputDecoration = BoxDecoration(
    border: Border.all(
      width: 0.1, // 枠線の幅を0.1に設定
      color: Colors.grey, // 枠線の色をグレーに設定
    ),
    borderRadius: BorderRadius.circular(4), // 枠線の角を丸くする
  );

  // 結果表示用の入力フィールドのデコレーション（枠線なし）
  static const InputDecoration resultInputDecoration = InputDecoration.collapsed(
    hintText: '', // ヒントテキストを空に設定
    border: OutlineInputBorder(
      borderSide: BorderSide(
        width: 0, // 枠線の幅を0に設定
        style: BorderStyle.none, // 枠線なし
      ),
    ),
  );
}
