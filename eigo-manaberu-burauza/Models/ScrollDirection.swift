//
//  ScrollDirection.swift
//  eigo-manaberu-burauza
//
//  スクロール方向を表す列挙型
//

/// ========================================
/// 📐 列挙型: ScrollDirection
/// 📌 目的: WebViewのスクロール方向を表す
/// ========================================
/// TypeScriptでいう:
///   type ScrollDirection = 'up' | 'down' | 'none'
enum ScrollDirection {
  case up      // 上方向にスクロール（ナビバー表示）
  case down    // 下方向にスクロール（ナビバー非表示）
  case none    // 変化なし
}
