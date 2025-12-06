//
//  BrowserNavigationBar.swift
//  eigo-manaberu-burauza
//
//  Safari風のブラウザナビゲーションバー
//

import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

/// ========================================
/// 🧩 View名: BrowserNavigationBar
/// 📌 目的: Safari風のブラウザナビゲーションバー（ミニ/フル切り替え）
/// ========================================
struct BrowserNavigationBar: View {
  // 🗂️ タブマネージャー
  @ObservedObject var tabManager: TabManager

  // 🔗 親から渡される状態
  @Binding var searchText: String
  @Binding var isTranslationMode: Bool
  @Binding var isNavBarHidden: Bool
  @Binding var selectedText: String

  var body: some View {
    // スクロール時は非表示、タップまたは上スクロールで表示
    if !isNavBarHidden {
      fullBar
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📐 フルバー（展開状態）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private var fullBar: some View {
    VStack(spacing: 8) {
      HStack(spacing: 12) {
        // 🔍 検索バー
        SearchBar(text: $searchText, isLoading: tabManager.activeTab?.isLoading ?? false) {
          tabManager.activeTab?.navigate(to: searchText)
        }

        // 🔄 リロード / ✕ 停止ボタン
        Button(action: {
          if tabManager.activeTab?.isLoading ?? false {
            tabManager.activeTab?.stopLoading()
          } else {
            tabManager.activeTab?.reload()
          }
        }) {
          Image(
            systemName: (tabManager.activeTab?.isLoading ?? false) ? "xmark" : "arrow.clockwise"
          )
          .font(.system(size: 18, weight: .medium))
          .frame(width: 44, height: 44)
        }
        .foregroundColor(.blue)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
    // 🌫️ 下部バーと同じブラー背景
    .background(.thickMaterial)
    .transition(.opacity)
  }
}
