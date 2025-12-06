//
//  BottomBar.swift
//  eigo-manaberu-burauza
//
//  下部のナビゲーションバー + 翻訳ミニバー（Music アプリ風）
//

import SwiftUI

/// ========================================
/// 🧩 View名: BottomBar
/// 📌 目的: 下部に表示するナビゲーション + 翻訳ミニバー
/// ========================================
/// Musicアプリの「Now Playing」バー風のデザイン
/// - 背景が透けて見えるブラーエフェクト
/// - 上スワイプでモーダルを開く
/// - タップでも開く
struct BottomBar: View {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔗 外部から受け取るプロパティ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @ObservedObject var tabManager: TabManager

  // 🔍 検索バー用
  @Binding var searchText: String

  // 翻訳関連
  let selectedText: String
  let translatedText: String
  let isLoadingTranslation: Bool
  let isSpeaking: Bool

  // 🔀 翻訳モード切り替え
  @Binding var isTranslationMode: Bool

  // 📍 表示/非表示の状態（スクロール連動）
  @Binding var isHidden: Bool

  // アクション
  let onSpeak: () -> Void
  let onExpandSheet: () -> Void

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 ジェスチャー用の状態
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @State private var dragOffset: CGFloat = 0
  @GestureState private var isDragging: Bool = false

  // 📤 共有シートの表示状態
  @State private var showShareSheet: Bool = false

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 body
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  var body: some View {
    VStack(spacing: 0) {
      // 🎵 翻訳ミニバー（翻訳モード時のみ表示）
      if isTranslationMode {
        translationMiniBar
      }

      // 🧭 ナビゲーションバー（スクロール時に隠れる）
      if !isHidden {
        navigationBar
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    // 🌫️ 全体の背景を透明に（下のWebViewが見えるように）
    .background(Color.clear)
    .animation(.easeInOut(duration: 0.25), value: isHidden)
    // 📤 共有シート
    .sheet(isPresented: $showShareSheet) {
      if let urlString = tabManager.activeTab?.url,
        let url = URL(string: urlString)
      {
        ShareSheet(activityItems: [url])
          .presentationDetents([.medium])  // 半分までのシートに固定
          .presentationDragIndicator(.visible)
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎵 翻訳ミニバー（Music アプリ Now Playing 風）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// TypeScriptでいう: React.FC でブラー背景のカードコンポーネント
  private var translationMiniBar: some View {
    HStack(spacing: 12) {
      // 📝 テキスト表示エリア
      VStack(alignment: .leading, spacing: 2) {
        if selectedText.isEmpty {
          Text("テキストを選択してください")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
        } else {
          // 選択テキスト（曲名に相当）
          Text(selectedText)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)

          // 翻訳テキスト（アーティスト名に相当）
          if isLoadingTranslation {
            HStack(spacing: 4) {
              ProgressView()
                .scaleEffect(0.5)
              Text("翻訳中...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
          } else if !translatedText.isEmpty {
            Text(translatedText)
              .font(.system(size: 13, weight: .regular))
              .foregroundColor(.blue)  // 青色に変更
              .lineLimit(1)
          }
        }
      }

      Spacer()

      // 🔊 スピーカーボタン
      if !selectedText.isEmpty {
        Button(action: onSpeak) {
          Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
            .font(.system(size: 20))
            .foregroundColor(isSpeaking ? .orange : .primary)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    // 🌫️ モーダルと同じ背景スタイル（透け感あり）
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.thickMaterial)  // モーダルに近いマテリアル
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -4)
    )
    .padding(.horizontal, 8)
    .padding(.bottom, 4)
    // 📍 ドラッグ中の位置オフセット
    .offset(y: min(0, dragOffset))
    // 🖐️ ジェスチャー（上スワイプで展開）
    .gesture(
      DragGesture()
        .updating($isDragging) { _, state, _ in
          state = true
        }
        .onChanged { value in
          // 上方向へのドラッグのみ反応（負の値）
          if value.translation.height < 0 {
            dragOffset = value.translation.height * 0.3  // 抵抗感を出す
          }
        }
        .onEnded { value in
          // 上に一定距離スワイプしたらシートを展開
          if value.translation.height < -50 {
            onExpandSheet()
          }
          // オフセットをリセット
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dragOffset = 0
          }
        }
    )
    // 👆 タップでシートを展開
    .onTapGesture {
      if !selectedText.isEmpty {
        onExpandSheet()
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧭 ナビゲーションバー（iOS 26風）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Safari 風の下部ツールバー + 検索バー
  private var navigationBar: some View {
    VStack(spacing: 8) {
      // 🔍 検索バー（iOS 26風に下部に配置）
      HStack(spacing: 8) {
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
          .font(.system(size: 16, weight: .medium))
          .frame(width: 36, height: 36)
        }
        .foregroundColor(.blue)
      }
      .padding(.horizontal, 8)

      // 🧭 ツールバーボタン
      HStack(spacing: 0) {
        // ⬅️ 戻るボタン
        ToolbarButton(
          systemName: "chevron.left",
          isEnabled: tabManager.activeTab?.canGoBack ?? false
        ) {
          tabManager.activeTab?.goBack()
        }

        Spacer()

        // ➡️ 進むボタン
        ToolbarButton(
          systemName: "chevron.right",
          isEnabled: tabManager.activeTab?.canGoForward ?? false
        ) {
          tabManager.activeTab?.goForward()
        }

        Spacer()

        // 📤 共有ボタン
        ToolbarButton(
          systemName: "square.and.arrow.up", isEnabled: tabManager.activeTab?.url.isEmpty == false
        ) {
          showShareSheet = true
        }

        Spacer()

        // 🔀 翻訳モード切り替えボタン
        Button(action: {
          isTranslationMode.toggle()
        }) {
          Image(systemName: isTranslationMode ? "character.bubble.fill" : "character.bubble")
            .font(.system(size: 20))
            .foregroundColor(isTranslationMode ? .orange : .primary)
            .frame(width: 44, height: 44)
        }

        Spacer()

        // 🗂️ タブボタン
        Button(action: {
          withAnimation(.easeInOut(duration: 0.3)) {
            // 📸 スクリーンショットを撮ってからタブ一覧を表示
            tabManager.openTabOverview()
          }
        }) {
          ZStack {
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color.primary, lineWidth: 1.5)
              .frame(width: 20, height: 20)
            Text("\(tabManager.tabs.count)")
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(.primary)
          }
          .frame(width: 44, height: 44)
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.top, 8)
    .padding(.bottom, 4)
    // 🌫️ ブラー背景
    .background(.ultraThinMaterial)
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧩 ツールバーボタン
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
private struct ToolbarButton: View {
  let systemName: String
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 20, weight: .regular))
        .frame(width: 44, height: 44)
    }
    .disabled(!isEnabled)
    .foregroundColor(isEnabled ? .primary : .gray.opacity(0.4))
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 👀 #Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#Preview {
  ZStack {
    // 背景テスト用
    LinearGradient(
      colors: [.blue, .purple],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    VStack {
      Spacer()
      BottomBar(
        tabManager: TabManager(),
        searchText: .constant(""),
        selectedText: "Hello World",
        translatedText: "こんにちは世界",
        isLoadingTranslation: false,
        isSpeaking: false,
        isTranslationMode: .constant(true),
        isHidden: .constant(false),
        onSpeak: {},
        onExpandSheet: {}
      )
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📤 ShareSheet（UIActivityViewController のラッパー）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: Reactコンポーネントでネイティブの共有ダイアログを表示するラッパー
// UIActivityViewController は UIKit の機能なので、SwiftUI で使うには
// UIViewControllerRepresentable でラップする必要がある
struct ShareSheet: UIViewControllerRepresentable {
  // 📦 共有するアイテム（URL、テキスト、画像など）
  let activityItems: [Any]

  // 🔧 UIViewControllerを作成
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  // 🔄 更新時の処理（今回は何もしない）
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
