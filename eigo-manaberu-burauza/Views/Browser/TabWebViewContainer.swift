//
//  TabWebViewContainer.swift
//  eigo-manaberu-burauza
//
//  Created by 萩 山登 on 2025/12/02.
//

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import SwiftUI

/// ========================================
/// 🧩 View名: TabWebViewContainer
/// 📌 目的: TabWebViewを表示するコンテナ
/// ========================================
/// 責務:
/// - TabWebViewのラッパーとして機能
/// - selectedTextの中継
/// - タブマネージャーとの接続
struct TabWebViewContainer: View {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📥 入力プロパティ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @ObservedObject var tabManager: TabManager
  @Binding var selectedText: String
  @Binding var isTranslationMode: Bool
  @Binding var isNavBarHidden: Bool

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 body
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  var body: some View {
    ZStack {
      // 🔄 各タブのWebViewを重ねて表示（アクティブなものだけ可視化）
      ForEach(tabManager.tabs) { tab in
        TabWebView(
          tab: tab,
          selectedText: $selectedText,
          isTranslationMode: $isTranslationMode,
          isActive: tab.id == tabManager.activeTabId,
          onScroll: handleScroll,
          tabManager: tabManager  // 🔗 target="_blank" リンクを新しいタブで開くために必要
        )
        .opacity(tab.id == tabManager.activeTabId ? 1 : 0)
        .allowsHitTesting(tab.id == tabManager.activeTabId)
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 スクロール処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// スクロール方向に応じてナビバーの表示/非表示を切り替え
  private func handleScroll(_ direction: ScrollDirection) {
    withAnimation(.easeInOut(duration: 0.25)) {
      switch direction {
      case .up:
        isNavBarHidden = false
      case .down:
        isNavBarHidden = true
      case .none:
        break
      }
    }
  }
}
