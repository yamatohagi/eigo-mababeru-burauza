//
//  TabOverviewView.swift
//  eigo-manaberu-burauza
//
//  Created by AI Assistant on 2025/12/05.
//

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import SwiftUI

/// ========================================
/// 🧩 View名: TabOverviewView
/// 📌 目的: iOS 26風のリッチなタブ一覧画面
/// ========================================
struct TabOverviewView: View {
  // 🗂️ タブマネージャー
  @ObservedObject var tabManager: TabManager

  // 🎨 環境変数
  @Environment(\.colorScheme) var colorScheme

  // 🎨 グリッドのカラム設定（2列）
  let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    ZStack {
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🎨 iOS 26風 グラデーション背景
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      LinearGradient(
        colors: colorScheme == .dark
          ? [Color(.systemGray6), Color(.systemGray5)]
          : [Color(.systemGray6), Color(.systemGray5).opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📜 スクロール可能なタブ一覧
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🔧 VStackを削除してScrollViewを直接配置（Spacerがスクロールを妨げていた）
      ScrollView(.vertical, showsIndicators: true) {
        LazyVGrid(columns: columns, spacing: 14) {
          // 📑 各タブをカードとして表示
          ForEach(tabManager.tabs) { tab in
            TabCardView(
              tab: tab,
              isActive: tab.id == tabManager.activeTabId,
              onTap: {
                // 🎯 タップでタブを選択して閉じる
                tabManager.switchToTab(tab)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                  tabManager.showTabOverview = false
                }
              },
              onClose: {
                // ❌ タブを閉じる
                withAnimation(.easeInOut(duration: 0.25)) {
                  tabManager.closeTab(tab)
                }
              }
            )
          }
        }
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 100)  // 下部ツールバーの余白
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🧭 iOS 26風 フローティングツールバー（下部）
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      VStack {
        Spacer()
        bottomToolbar
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧭 下部ツールバー（iOS 26 Liquid Glass風）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private var bottomToolbar: some View {
    HStack(spacing: 0) {
      // ＋ 新規タブボタン（左）
      Button(action: {
        tabManager.addTab()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
          tabManager.showTabOverview = false
        }
      }) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.primary)
          .padding(12)
          .background(
            Circle()
              .fill(.ultraThinMaterial)
              .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
          )
      }

      Spacer()

      // 📑 タブ数表示（中央ピル）
      Text("\(tabManager.tabs.count)個のタブ")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)

      Spacer()

      // ✓ 完了ボタン（右）
      Button(action: {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
          tabManager.showTabOverview = false
        }
      }) {
        Text("完了")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.white)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(
            Capsule()
              .fill(Color.blue)
              .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
          )
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      // 🌫️ Liquid Glass 風ブラー背景
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
    )
    .padding(.horizontal, 12)
    .padding(.bottom, 8)
  }
}

/// ========================================
/// 🧩 View名: TabCardView
/// 📌 目的: iOS 26風のリッチなタブカード（パフォーマンス最適化版）
/// ========================================
struct TabCardView: View {
  // 📑 表示するタブ（letに変更して不要な監視を防ぐ）
  let tab: BrowserTab
  // 🎯 アクティブかどうか
  let isActive: Bool
  // 👆 タップ時のアクション
  let onTap: () -> Void
  // ❌ 閉じるアクション
  let onClose: () -> Void

  // 👈 スワイプ用のオフセット
  @State private var swipeOffset: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📸 タブのスクリーンショットプレビュー
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ZStack {
        // 🎨 カード背景（シンプルな背景色に変更 - ブラーは重い）
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.secondarySystemBackground))

        // 📸 スクリーンショットがあれば表示
        if let screenshot = tab.screenshot {
          Image(uiImage: screenshot)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
        } else {
          // 🌐 スクリーンショットがない場合はプレースホルダー（シンプル版）
          VStack(spacing: 10) {
            Image(systemName: "globe")
              .font(.system(size: 32, weight: .medium))
              .foregroundColor(.blue)

            Text(tab.displayHost)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }
      }
      .frame(height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // ❌ 閉じるボタン（右上）
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      .overlay(
        Button(action: onClose) {
          ZStack {
            // 背景のブラー
            Circle()
              .fill(.ultraThinMaterial)
              .frame(width: 26, height: 26)

            Image(systemName: "xmark")
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(.secondary)
          }
          .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
        }
        .padding(8),
        alignment: .topTrailing
      )
      .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📝 タブのタイトル
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      HStack(spacing: 6) {
        // 🌐 ファビコン風アイコン
        Image(systemName: "globe")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)

        Text(tab.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.primary)
          .lineLimit(1)
      }
      .padding(.top, 10)
      .padding(.horizontal, 4)
    }
    // 👈 左スワイプでタブを削除（スクロールを優先）
    .offset(x: swipeOffset)
    .highPriorityGesture(
      DragGesture(minimumDistance: 30)  // 🔧 最小距離を増やしてスクロールと確実に区別
        .onChanged { value in
          // 📐 水平方向の移動が垂直より大幅に大きい場合のみ反応
          let horizontalAmount = abs(value.translation.width)
          let verticalAmount = abs(value.translation.height)
          
          // 水平スワイプが明らかな場合のみ（水平が垂直の3倍以上 & 左方向）
          if horizontalAmount > verticalAmount * 3 && value.translation.width < -20 {
            swipeOffset = value.translation.width
          }
        }
        .onEnded { value in
          // 📏 一定以上スワイプしたら削除
          if swipeOffset < -80 {
            withAnimation(.easeInOut(duration: 0.2)) {
              swipeOffset = -500
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              onClose()
            }
          } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
              swipeOffset = 0
            }
          }
        }
    )
    .simultaneousGesture(TapGesture().onEnded {
      // 👆 タップでタブを切り替えて閉じる
      onTap()
    })
  }
}
