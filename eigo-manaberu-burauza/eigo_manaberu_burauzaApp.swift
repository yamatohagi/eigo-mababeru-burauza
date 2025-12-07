//
//  eigo_manaberu_burauzaApp.swift
//  eigo-manaberu-burauza
//
//  Created by 萩 山登 on 2025/12/02.
//

import Combine
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔗 URLスキームで共有されたURLを管理するシングルトン
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう:
//   class SharedURLManager {
//     static instance = new SharedURLManager();
//     pendingURL: string | null = null;
//   }
//
// 📌 目的: 他アプリからURLスキームで開かれた時のURLを一時保存
class SharedURLManager: ObservableObject {
  static let shared = SharedURLManager()

  // 🌐 開くべきURL（nilなら何もしない）
  @Published var pendingURL: URL?

  private init() {}
}

@main
struct eigo_manaberu_burauzaApp: App {
  // 📱 共有URLマネージャーを監視
  @StateObject private var sharedURLManager = SharedURLManager.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 🔗 URLスキームで開かれた時の処理
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // TypeScriptでいう: window.addEventListener('customurl', (e) => { ... })
        //
        // 📌 目的: eigobrowser://open?url=https://... 形式のURLを受け取る
        // 例: eigobrowser://open?url=https://bbc.com
        .onOpenURL { url in
          handleIncomingURL(url)
        }
        // 📱 App Groups経由で共有されたURLをチェック（Share Extension用）
        .onAppear {
          checkForSharedURL()
        }
        // 🔄 アプリがアクティブになった時も共有URLをチェック
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
          checkForSharedURL()
        }
        // 📦 共有URLマネージャーを環境に注入
        .environmentObject(sharedURLManager)
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 URLスキームの処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📌 目的: eigobrowser://open?url=... を解析してURLを取り出す
  private func handleIncomingURL(_ url: URL) {
    // URLスキームが "eigobrowser" の場合のみ処理
    guard url.scheme == "eigobrowser" else { return }

    // "open" コマンドかチェック
    guard url.host == "open" else { return }

    // クエリパラメータから "url" を取得
    // 例: eigobrowser://open?url=https://bbc.com
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value,
      let targetURL = URL(string: urlParam)
    {
      // 🌐 開くべきURLを設定
      sharedURLManager.pendingURL = targetURL
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 App Groups経由の共有URLをチェック
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📌 目的: Share Extensionから保存されたURLを取得して開く
  private func checkForSharedURL() {
    // 📦 App Groupsの共有UserDefaults
    // ⚠️ App Groups設定後に "group.your.app.identifier" を実際のIDに変更
    guard let userDefaults = UserDefaults(suiteName: "group.eigobrowser.shared") else { return }

    // 🌐 共有されたURLを取得
    if let urlString = userDefaults.string(forKey: "SharedURL"),
      let url = URL(string: urlString)
    {
      // URLを設定
      sharedURLManager.pendingURL = url
      // 取得後は削除
      userDefaults.removeObject(forKey: "SharedURL")
    }
  }
}
