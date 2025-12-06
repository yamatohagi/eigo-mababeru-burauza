//
//  TranslationViewModel.swift
//  eigo-manaberu-burauza
//
//  翻訳機能の状態とロジックを管理するViewModel
//

import AVFoundation
import Combine
import SwiftUI
import Translation

/// ========================================
/// 🎮 クラス名: TranslationViewModel
/// 📌 目的: 翻訳機能の状態管理とビジネスロジック
/// ========================================
// TypeScriptでいう:
//   class TranslationViewModel {
//     selectedText: string = "";
//     translatedText: string = "";
//     // ... etc
//   }
@MainActor
class TranslationViewModel: ObservableObject {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📝 選択テキスト関連
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @Published var selectedText: String = ""
  @Published var translatedText: String = ""
  @Published var contextExplanation: String = ""
  @Published var dictionaryInfo: String = ""

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ⏳ ローディング状態
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @Published var isLoadingTranslation: Bool = false
  @Published var isLoadingContext: Bool = false
  @Published var isLoadingDictionary: Bool = false

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 UI状態
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @Published var isExplanationExpanded: Bool = true
  @Published var sheetDetent: PresentationDetent = .height(75)
  @Published var isTranslationSheetPresented: Bool = true

  // 💬 チャット機能
  @Published var chatMessages: [ChatMessage] = []
  @Published var chatInput: String = ""
  @Published var isLoadingChat: Bool = false

  // ❌ エラー
  @Published var errorMessage: String? = nil

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🍎 Apple Translation
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @Published var translationConfig: TranslationSession.Configuration? = nil
  @Published var textToTranslate: String = ""

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔊 音声再生
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @Published var isSpeaking: Bool = false

  // 🔧 サービス
  private let translationService = TranslationService()
  private let speechService = SpeechService()

  init() {
    // 音声再生状態の監視
    speechService.onSpeakingChanged = { [weak self] speaking in
      self?.isSpeaking = speaking
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 状態リセット
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 翻訳関連の状態をすべてリセット
  func resetTranslationState() {
    selectedText = ""
    translatedText = ""
    contextExplanation = ""
    dictionaryInfo = ""
    errorMessage = nil
    isExplanationExpanded = false
    sheetDetent = .height(75)
    chatMessages = []
    chatInput = ""
  }

  /// テキスト選択時のリセット（翻訳結果のみ）
  func resetForNewSelection() {
    translatedText = ""
    contextExplanation = ""
    dictionaryInfo = ""
    errorMessage = nil
    isExplanationExpanded = false
    chatMessages = []
    chatInput = ""
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🍎 Apple翻訳を実行
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func triggerTranslation() {
    guard !selectedText.isEmpty else { return }

    isLoadingTranslation = true
    errorMessage = nil
    translatedText = ""
    textToTranslate = selectedText

    // configがあればinvalidate、なければ新規作成
    if translationConfig != nil {
      translationConfig?.invalidate()
    } else {
      translationConfig = TranslationSession.Configuration(
        source: Locale.Language(identifier: "en"),
        target: Locale.Language(identifier: "ja")
      )
    }
  }

  /// Apple Translation タスクからの結果を処理
  func handleTranslationResult(_ result: Result<String, Error>) {
    switch result {
    case .success(let text):
      translatedText = text
    case .failure(let error):
      let errorDesc = error.localizedDescription
      // キャンセルエラーは無視
      if !errorDesc.contains("cancelled") && !errorDesc.contains("couldn't be completed") {
        errorMessage = "翻訳エラー: \(errorDesc)"
      }
    }
    isLoadingTranslation = false
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🤖 AI解説を取得
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func fetchAIExplanation() {
    guard !selectedText.isEmpty else { return }

    Task {
      isLoadingContext = true
      errorMessage = nil

      do {
        let explanation = try await translationService.explainText(selectedText)
        contextExplanation = explanation
        isExplanationExpanded = true
      } catch {
        errorMessage = error.localizedDescription
      }

      isLoadingContext = false
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💬 チャットで追加質問
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// ユーザーの質問をAIに送信して回答を得る
  func sendChatMessage() {
    let userMessage = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !userMessage.isEmpty else { return }

    // 入力をクリア＆ユーザーメッセージを追加
    chatInput = ""
    chatMessages.append(ChatMessage(content: userMessage, isUser: true))

    Task {
      isLoadingChat = true

      do {
        // 文脈を含めたメッセージ配列を構築
        var messagesForAPI: [ChatMessage] = []

        // 元のテキストと解説を最初のコンテキストとして追加
        let context = """
          【選択テキスト】
          \(selectedText)

          【翻訳】
          \(translatedText)

          【AI解説】
          \(contextExplanation)
          """
        messagesForAPI.append(ChatMessage(content: context, isUser: true))
        messagesForAPI.append(ChatMessage(content: "この内容について質問があればどうぞ！", isUser: false))

        // 既存のチャット履歴を追加
        messagesForAPI.append(contentsOf: chatMessages)

        let response = try await translationService.chat(messages: messagesForAPI)
        chatMessages.append(ChatMessage(content: response, isUser: false))
      } catch {
        chatMessages.append(
          ChatMessage(content: "エラー: \(error.localizedDescription)", isUser: false))
      }

      isLoadingChat = false
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📚 辞書情報を取得
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func fetchDictionaryInfo() {
    let word = selectedText
    guard !word.isEmpty else { return }

    Task {
      isLoadingDictionary = true
      dictionaryInfo = ""

      do {
        let info = try await translationService.getDictionaryInfo(word)
        dictionaryInfo = info
      } catch {
        // 辞書エラーは静かに無視
        print("❌ [fetchDictionaryInfo] APIエラー: \(error)")
      }

      isLoadingDictionary = false
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔊 音声読み上げ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func speakSelectedText() {
    guard !selectedText.isEmpty else { return }
    isSpeaking = true
    speechService.speak(selectedText, language: "en-US")
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 タブ一覧表示時の処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func handleTabOverviewVisibilityChange(isShowing: Bool) {
    if isShowing {
      isTranslationSheetPresented = false
      sheetDetent = .height(75)
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        self?.sheetDetent = .height(75)
        self?.isTranslationSheetPresented = true
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📝 テキスト選択時の処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func handleSelectedTextChange(_ newValue: String) {
    guard !newValue.isEmpty else {
      resetTranslationState()
      return
    }

    resetForNewSelection()
    triggerTranslation()

    // 単語の場合は辞書も取得
    if !newValue.contains(" ") && newValue.count <= 30 {
      fetchDictionaryInfo()
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📏 シート展開時の処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func handleSheetDetentChange(from oldValue: PresentationDetent, to newValue: PresentationDetent) {
    // ミニバー → 中サイズに展開された時
    if oldValue == .height(75) && newValue == .medium {
      if !selectedText.isEmpty && contextExplanation.isEmpty && !isLoadingContext {
        fetchAIExplanation()
      }
    }
  }
}
