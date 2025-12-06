//
//  TranslationService.swift
//  eigo-manaberu-burauza
//
//  Created by AI Assistant on 2025/12/03.
//

import Foundation

/// ========================================
/// 🌐 TranslationService
/// 📌 目的: バックエンドAPI経由でAI解説機能を提供
/// 📝 処理概要:
///   - explainText: 文法や表現のポイントを解説
///   - getDictionaryInfo: 辞書情報を取得
///   - chat: チャット形式で追加質問
/// ========================================

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔧 actor について
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: class TranslationService（ただしスレッドセーフ）
// actor = 複数の処理が同時にアクセスしても安全なクラス
// API通信は非同期で行われるので、actorを使うと安全
actor TranslationService {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔑 設定
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 本番用: Cloudflare Workers URL
  // ローカル開発用: MacのIPアドレス
  #if DEBUG
    private let apiBaseURL = "http://192.168.151.29:8787"
  #else
    private let apiBaseURL = "https://eigo-browser-api.la-luce-ymt0326.workers.dev"
  #endif  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🤖 AI解説を取得
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func explainText(_ text: String) async throws -> String {
    return try await callAPI(text: text, type: "explain")
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📚 辞書的な情報を取得（単語向け）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func getDictionaryInfo(_ word: String) async throws -> String {
    return try await callAPI(text: word, type: "dictionary")
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💬 チャット形式で追加質問（会話履歴を保持）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func chat(messages: [ChatMessage]) async throws -> String {
    return try await callAPI(text: "", type: "chat", messages: messages)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 共通API呼び出し
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func callAPI(text: String, type: String, messages: [ChatMessage]? = nil) async throws
    -> String
  {
    guard let url = URL(string: apiBaseURL) else {
      throw TranslationError.invalidURL
    }

    var requestBody: [String: Any] = [
      "text": text,
      "type": type,
    ]

    // チャットの場合はメッセージ履歴も送信
    if let messages = messages {
      requestBody["messages"] = messages.map { msg in
        ["content": msg.content, "isUser": msg.isUser]
      }
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // 🔐 シークレットキーをヘッダーに追加（アプリ認証用）
    request.addValue(APISecrets.apiSecretKey, forHTTPHeaderField: "X-API-Key")
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw TranslationError.apiError
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let result = json["result"] as? String
    else {
      throw TranslationError.parseError
    }

    return result
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 💬 ChatMessage - チャットメッセージの構造体
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: interface ChatMessage { id: string; content: string; isUser: boolean }
struct ChatMessage: Identifiable, Equatable {
  let id: UUID
  let content: String
  let isUser: Bool  // true = ユーザー、false = AI

  init(content: String, isUser: Bool) {
    self.id = UUID()
    self.content = content
    self.isUser = isUser
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ❌ TranslationError - エラー定義
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum TranslationError: Error, LocalizedError {
  case invalidURL
  case apiError
  case parseError

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid URL"
    case .apiError: return "API Error"
    case .parseError: return "Parse Error"
    }
  }
}
