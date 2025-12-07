//
//  ContentView.swift
//  eigo-manaberu-burauza
//
//  Created by 萩 山登 on 2025/12/02.
//

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import Inject
import SwiftUI
import Translation

/// ========================================
/// 🧩 View名: ContentView
/// 📌 目的: アプリのメイン画面（各コンポーネントを統合）
/// ========================================
/// 責務:
/// - 各ViewとViewModelの統合
/// - 画面レイアウトの構築
/// - モディファイアの適用
struct ContentView: View {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎮 ViewModels & Managers
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @StateObject private var tabManager = TabManager()
  @StateObject private var translationVM = TranslationViewModel()

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 ローカル状態
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @State private var searchText: String = ""
  @State private var isTranslationMode: Bool = false
  @State private var isNavBarHidden: Bool = false

  // 🔥 Hot Reload用
  @ObserveInjection var inject

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 body
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  var body: some View {
    ZStack(alignment: .bottom) {
      // 📱 メインコンテンツ
      VStack(spacing: 0) {
        // 🌐 WebView（画面全体に広がる）
        TabWebViewContainer(
          tabManager: tabManager,
          selectedText: $translationVM.selectedText,
          isTranslationMode: $isTranslationMode,
          isNavBarHidden: $isNavBarHidden
        )
      }
      .ignoresSafeArea(.container, edges: .bottom)  // 🔧 下部まで広げる

      // 🔀 翻訳モード切り替えフローティングボタン（ドラッグ移動可能）
      DraggableTranslationButton(isTranslationMode: $isTranslationMode)

      // 📱 下部バー（検索バー + 翻訳ミニバー + ナビゲーション）オーバーレイ
      BottomBar(
        tabManager: tabManager,
        searchText: $searchText,
        selectedText: translationVM.selectedText,
        translatedText: translationVM.translatedText,
        isLoadingTranslation: translationVM.isLoadingTranslation,
        isSpeaking: translationVM.isSpeaking,
        isTranslationMode: $isTranslationMode,  // 🔀 翻訳モード切り替え
        isHidden: $isNavBarHidden,  // 🔄 スクロール連動（タップで表示可能）
        onSpeak: { translationVM.speakSelectedText() },
        onExpandSheet: {
          // 🚀 シートを中サイズに展開
          withAnimation {
            translationVM.sheetDetent = .medium
          }
        }
      )

      // 👆 ホームインジケーター周辺のタップ領域（バー非表示時のみ）
      if isNavBarHidden {
        VStack {
          Spacer()
          // 📍 タップ可能なことを示す小さなピル型インジケーター
          Capsule()
            .fill(.ultraThinMaterial)
            .frame(width: 60, height: 8)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            .padding(.bottom, 10)
            .contentShape(Rectangle().size(width: 120, height: 50))  // タップ領域を広げる
            .onTapGesture {
              withAnimation(.easeInOut(duration: 0.25)) {
                isNavBarHidden = false
              }
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
      }
    }
    // 🗂️ タブ一覧オーバーレイ
    .fullScreenCover(isPresented: $tabManager.showTabOverview) {
      TabOverviewView(tabManager: tabManager)
    }
    // タブ一覧表示時のシート制御
    .onChange(of: tabManager.showTabOverview) { _, isShowing in
      translationVM.handleTabOverviewVisibilityChange(isShowing: isShowing)
    }
    // 🔥 Hot Reload
    .enableInjection()
    // 📋 翻訳シート（展開時のみ表示）
    .sheet(
      isPresented: Binding(
        get: { translationVM.sheetDetent == .medium },
        set: { if !$0 { translationVM.sheetDetent = .height(75) } }
      )
    ) {
      TranslationSheetView(
        selectedText: translationVM.selectedText,
        translatedText: translationVM.translatedText,
        dictionaryInfo: translationVM.dictionaryInfo,
        isLoadingDictionary: translationVM.isLoadingDictionary,
        isSpeaking: translationVM.isSpeaking,
        contextExplanation: translationVM.contextExplanation,
        isExplanationExpanded: $translationVM.isExplanationExpanded,
        isLoadingTranslation: translationVM.isLoadingTranslation,
        isLoadingContext: translationVM.isLoadingContext,
        errorMessage: translationVM.errorMessage,
        sheetDetent: $translationVM.sheetDetent,
        chatMessages: translationVM.chatMessages,
        chatInput: $translationVM.chatInput,
        isLoadingChat: translationVM.isLoadingChat,
        onSendChat: { translationVM.sendChatMessage() },
        onExplain: { translationVM.fetchAIExplanation() },
        onSpeak: { translationVM.speakSelectedText() }
      )
      .presentationDetents([.medium, .large])
      .presentationContentInteraction(.scrolls)
      .presentationDragIndicator(.visible)
    }
    // 🍎 Apple Translation タスク
    .translationTask(translationVM.translationConfig) { session in
      guard !translationVM.textToTranslate.isEmpty else {
        translationVM.isLoadingTranslation = false
        return
      }
      do {
        let response = try await session.translate(translationVM.textToTranslate)
        translationVM.handleTranslationResult(.success(response.targetText))
      } catch {
        translationVM.handleTranslationResult(.failure(error))
      }
    }
    // 🔄 テキスト選択時の処理
    .onChange(of: translationVM.selectedText) { _, newValue in
      translationVM.handleSelectedTextChange(newValue)
    }
    // 📏 シート展開時の処理
    .onChange(of: translationVM.sheetDetent) { oldValue, newValue in
      translationVM.handleSheetDetentChange(from: oldValue, to: newValue)
    }
    // 🗂️ タブ切り替え時のリセット
    .onChange(of: tabManager.activeTabId) { _, _ in
      translationVM.resetTranslationState()
    }
    // 🔗 共有URLを受け取ったら新しいタブで開く
    .onReceive(SharedURLManager.shared.$pendingURL) { url in
      if let url = url {
        // 📱 タブ一覧が開いていたら閉じる
        if tabManager.showTabOverview {
          tabManager.showTabOverview = false
        }
        // 新しいタブでURLを開く
        tabManager.addTab(url: url.absoluteString)
        // 処理完了後にリセット
        SharedURLManager.shared.pendingURL = nil
      }
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔀 DraggableTranslationButton - ドラッグ移動可能な翻訳ボタン
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📌 目的: 翻訳モード切り替えボタン（ドラッグで自由に移動可能）
/// - 初期位置: 画面下部中央
/// - サイズ: 大きめで見やすい
/// - ドラッグ: 好きな場所に移動可能
struct DraggableTranslationButton: View {
  @Binding var isTranslationMode: Bool

  // 📍 ボタンの位置（初期値は画面下部中央）
  @State private var position: CGPoint = .zero
  @State private var isDragging: Bool = false

  var body: some View {
    GeometryReader { geometry in
      Button(action: {
        withAnimation(.easeInOut(duration: 0.2)) {
          isTranslationMode.toggle()
        }
      }) {
        HStack(spacing: 8) {
          Image(systemName: isTranslationMode ? "character.bubble.fill" : "character.bubble")
            .font(.system(size: 18, weight: .semibold))
          Text(isTranslationMode ? "翻訳ON" : "翻訳")
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(isTranslationMode ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          Capsule()
            .fill(isTranslationMode ? Color.orange : Color(.systemBackground))
            .shadow(
              color: .black.opacity(isDragging ? 0.3 : 0.2), radius: isDragging ? 8 : 5, x: 0, y: 3)
        )
        .scaleEffect(isDragging ? 1.1 : 1.0)
      }
      .position(position == .zero ? initialPosition(in: geometry) : position)
      .gesture(
        DragGesture()
          .onChanged { value in
            isDragging = true
            position = value.location
          }
          .onEnded { value in
            isDragging = false
            // 画面端にスナップさせる（オプション）
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              position = constrainToScreen(value.location, in: geometry)
            }
          }
      )
      .onAppear {
        // 初期位置を設定
        position = initialPosition(in: geometry)
      }
    }
  }

  // 📍 初期位置（画面右端の縦方向中央）
  private func initialPosition(in geometry: GeometryProxy) -> CGPoint {
    CGPoint(
      x: geometry.size.width - 50,  // 右端から50pt内側
      y: geometry.size.height / 2  // 縦方向の中央
    )
  }

  // 📏 画面内に収める
  private func constrainToScreen(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
    let padding: CGFloat = 50
    let x = min(max(point.x, padding), geometry.size.width - padding)
    let y = min(max(point.y, padding + 50), geometry.size.height - padding - 100)
    return CGPoint(x: x, y: y)
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 👀 #Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#Preview {
  ContentView()
}
