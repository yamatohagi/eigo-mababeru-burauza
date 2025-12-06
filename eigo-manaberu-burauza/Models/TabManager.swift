//
//  TabManager.swift
//  eigo-manaberu-burauza
//
//  Created by AI Assistant on 2025/12/05.
//

import Combine
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import SwiftUI
import WebKit

/// ========================================
/// 🗂️ クラス名: BrowserTab
/// 📌 目的: 1つのタブを表すデータモデル
/// ========================================
// TypeScriptでいう:
//   interface BrowserTab {
//     id: string;
//     title: string;
//     url: string;
//     webView: WKWebView;
//   }
//
// Identifiable = ForEachでループする時にIDが必要
// ObservableObject = 状態変更を監視可能に
class BrowserTab: Identifiable, ObservableObject {
  // 🔑 一意なID（UUIDで自動生成）
  let id = UUID()

  // 📝 タブの情報（@Publishedで変更を通知）
  @Published var title: String = "新規タブ"
  @Published var url: String = ""
  @Published var canGoBack: Bool = false
  @Published var canGoForward: Bool = false
  @Published var isLoading: Bool = false

  // 📸 タブのスクリーンショット（タブ一覧で表示）
  // TypeScriptでいう: screenshot: UIImage | null
  @Published var screenshot: UIImage?

  // 🔍 KVO監視用
  private var observers: [NSKeyValueObservation] = []

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🌐 WKWebView（各タブが独自のWebViewを保持）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔥 重要: これがSafari風タブの核心！
  // 各タブがWebViewを保持することで、タブ切り替え時に状態が維持される
  let webView: WKWebView

  // 📱 ドメイン名だけを表示
  var displayHost: String {
    guard let urlObj = URL(string: url),
      let host = urlObj.host
    else {
      return "新規タブ"
    }
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 初期化
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  init(url: String = "https://www.reddit.com/") {
    self.url = url

    // 🌐 WKWebViewの設定
    let configuration = WKWebViewConfiguration()

    // 🎬 動画をインライン再生する（全画面にしない）
    // TypeScriptでいう: { playsinline: true } のような設定
    // これがないと動画タップで全画面再生になってしまう
    configuration.allowsInlineMediaPlayback = true

    // 🔇 ユーザー操作なしで自動再生を許可（ミュート状態で）
    // Safari と同じ挙動にする
    configuration.mediaTypesRequiringUserActionForPlayback = []

    self.webView = WKWebView(frame: .zero, configuration: configuration)

    // 🌐 SafariのUser-Agentを設定（Googleログイン等で必要）
    // デフォルトのWKWebView User-Agentだと「安全なブラウザ」として認識されず
    // Googleログインがブロックされる（error 403: disallowed_useragent）
    self.webView.customUserAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    // 👆 Safari風スワイプジェスチャー（左右で戻る・進む）
    self.webView.allowsBackForwardNavigationGestures = true

    // 🚫 リンクプレビュー無効化
    self.webView.allowsLinkPreview = false

    // 🚀 初期URLを読み込み
    if let initialURL = URL(string: url) {
      self.webView.load(URLRequest(url: initialURL))
    }

    // 🔍 KVO監視を設定（canGoBack/canGoForward をリアルタイムで監視）
    setupObservers()
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 KVO監視を設定
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func setupObservers() {
    // 📱 canGoBack を監視
    observers.append(
      webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.canGoBack = webView.canGoBack
        }
      }
    )

    // 📱 canGoForward を監視
    observers.append(
      webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.canGoForward = webView.canGoForward
        }
      }
    )

    // 📱 isLoading を監視
    observers.append(
      webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.isLoading = webView.isLoading
        }
      }
    )

    // 📱 URL を監視
    observers.append(
      webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.url = webView.url?.absoluteString ?? ""
        }
      }
    )

    // 📱 title を監視
    observers.append(
      webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.title = webView.title ?? self?.displayHost ?? "新規タブ"
        }
      }
    )
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎮 ナビゲーション操作
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func goBack() {
    webView.goBack()
  }

  func goForward() {
    webView.goForward()
  }

  func reload() {
    webView.reload()
  }

  func stopLoading() {
    webView.stopLoading()
  }

  // 🌐 URLに移動 or 検索
  func navigate(to input: String) {
    var urlString = input.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !urlString.isEmpty else { return }

    // URLっぽいかどうか判定
    let isURL = urlString.contains(".") && !urlString.contains(" ")

    if isURL {
      if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
        urlString = "https://" + urlString
      }
    } else {
      // 検索ワードの場合: Google検索URLに変換
      let encoded =
        urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
      urlString = "https://www.google.com/search?q=\(encoded)"
    }

    if let url = URL(string: urlString) {
      webView.load(URLRequest(url: url))
    }
  }

  // 🔄 状態を更新（Coordinatorから呼ばれる）
  func updateState() {
    DispatchQueue.main.async {
      self.canGoBack = self.webView.canGoBack
      self.canGoForward = self.webView.canGoForward
      self.url = self.webView.url?.absoluteString ?? ""
      self.title = self.webView.title ?? self.displayHost
      self.isLoading = self.webView.isLoading
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📸 スクリーンショットを撮影
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: async captureScreenshot(): Promise<void>
  // タブ一覧を開く時に呼ばれて、現在のWebView画面をキャプチャする
  func captureScreenshot() {
    // 📐 スクリーンショットの設定
    let config = WKSnapshotConfiguration()

    // 📸 WKWebViewのスナップショット機能を使用
    // TypeScriptでいう: await webView.takeScreenshot()
    webView.takeSnapshot(with: config) { [weak self] image, error in
      if let image = image {
        DispatchQueue.main.async {
          self?.screenshot = image
        }
      }
    }
  }
}

/// ========================================
/// 🎮 クラス名: TabManager
/// 📌 目的: 複数タブを管理するマネージャー
/// ========================================
// TypeScriptでいう:
//   class TabManager {
//     tabs: BrowserTab[] = [];
//     activeTabId: string | null = null;
//   }
class TabManager: ObservableObject {
  // 📑 全てのタブ
  @Published var tabs: [BrowserTab] = []

  // 🎯 現在アクティブなタブのID
  @Published var activeTabId: UUID?

  // 📑 タブ一覧画面の表示状態
  @Published var showTabOverview: Bool = false

  // 🔍 現在のアクティブタブを取得
  var activeTab: BrowserTab? {
    tabs.first { $0.id == activeTabId }
  }

  // 🔗 アクティブタブの変更を購読するためのキャンセラブル
  // TypeScriptでいう: subscription: Subscription | null
  private var activeTabCancellable: AnyCancellable?

  // 💾 タブのURL変更を監視して保存するためのキャンセラブル
  private var tabUrlObservers: [UUID: AnyCancellable] = [:]

  // 📱 アプリのライフサイクル監視用
  private var appLifecycleCancellable: AnyCancellable?

  // 💾 UserDefaultsのキー
  private static let savedTabsKey = "savedTabUrls"
  private static let activeTabIndexKey = "activeTabIndex"

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 初期化
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  init() {
    // 💾 保存されたタブを復元
    if let savedUrls = UserDefaults.standard.stringArray(forKey: Self.savedTabsKey),
      !savedUrls.isEmpty
    {
      // 保存されたURLからタブを復元
      for urlString in savedUrls {
        let tab = BrowserTab(url: urlString)
        tabs.append(tab)
        observeTabUrlChanges(tab)
      }

      // アクティブタブを復元
      let activeIndex = UserDefaults.standard.integer(forKey: Self.activeTabIndexKey)
      let safeIndex = min(activeIndex, tabs.count - 1)
      if safeIndex >= 0 && safeIndex < tabs.count {
        activeTabId = tabs[safeIndex].id
        subscribeToActiveTab(tabs[safeIndex])
      }
    } else {
      // 🚀 保存がなければ初期タブを1つ作成
      let initialTab = BrowserTab()
      tabs.append(initialTab)
      activeTabId = initialTab.id
      subscribeToActiveTab(initialTab)
      observeTabUrlChanges(initialTab)
    }

    // 📱 アプリがバックグラウンドに入る時にタブを保存
    appLifecycleCancellable = NotificationCenter.default
      .publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        self?.saveTabs()
      }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 タブのURLを保存
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func saveTabs() {
    // 各タブのURLを配列として保存
    // WebViewの現在のURLを優先的に使用（より正確）
    let urls = tabs.map { tab -> String in
      if let currentUrl = tab.webView.url?.absoluteString, !currentUrl.isEmpty {
        return currentUrl
      } else if !tab.url.isEmpty {
        return tab.url
      } else {
        return "https://www.reddit.com/"
      }
    }
    UserDefaults.standard.set(urls, forKey: Self.savedTabsKey)

    // アクティブタブのインデックスを保存
    if let activeId = activeTabId,
      let activeIndex = tabs.firstIndex(where: { $0.id == activeId })
    {
      UserDefaults.standard.set(activeIndex, forKey: Self.activeTabIndexKey)
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 タブのURL変更を監視
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func observeTabUrlChanges(_ tab: BrowserTab) {
    tabUrlObservers[tab.id] = tab.$url
      .debounce(for: .seconds(1), scheduler: RunLoop.main)  // 1秒待ってから保存（頻繁な保存を防ぐ）
      .sink { [weak self] _ in
        self?.saveTabs()
      }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 アクティブタブの変更を購読
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: subscribeToActiveTab(tab: BrowserTab): void
  // タブの状態（canGoBack/canGoForward等）が変わった時にTabManagerの更新を通知する
  private func subscribeToActiveTab(_ tab: BrowserTab) {
    // 🔗 タブの objectWillChange を購読
    // → タブの@Publishedプロパティが変更されると、TabManagerも更新通知を出す
    activeTabCancellable = tab.objectWillChange.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ➕ 新しいタブを追加
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func addTab(url: String = "https://bbc.com") {
    let newTab = BrowserTab(url: url)
    tabs.append(newTab)
    activeTabId = newTab.id
    // 🔄 新しいタブの状態変更を購読
    subscribeToActiveTab(newTab)
    observeTabUrlChanges(newTab)
    // 💾 タブを保存
    saveTabs()
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ❌ タブを閉じる
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func closeTab(_ tab: BrowserTab) {
    // 🔍 URL監視を解除
    tabUrlObservers.removeValue(forKey: tab.id)

    if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
      tabs.remove(at: index)

      // 🔄 タブが0になったら自動で新しいタブを作成
      if tabs.isEmpty {
        let newTab = BrowserTab()
        tabs.append(newTab)
        activeTabId = newTab.id
        subscribeToActiveTab(newTab)
        observeTabUrlChanges(newTab)
      } else if activeTabId == tab.id {
        // 閉じたタブがアクティブだった場合、隣のタブをアクティブに
        let newIndex = min(index, tabs.count - 1)
        let newActiveTab = tabs[newIndex]
        activeTabId = newActiveTab.id
        subscribeToActiveTab(newActiveTab)
      }
      // 💾 タブを保存
      saveTabs()
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 タブを切り替え
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func switchToTab(_ tab: BrowserTab) {
    activeTabId = tab.id
    // 🔄 新しいタブの状態変更を購読
    subscribeToActiveTab(tab)
    // 💾 アクティブタブを保存
    saveTabs()
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📸 タブ一覧を開く（スクリーンショット撮影付き）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: openTabOverview(): void
  // タブ一覧を開く前に、アクティブなタブのスクリーンショットを撮る
  func openTabOverview() {
    // 📸 アクティブなタブのスクリーンショットを撮影
    activeTab?.captureScreenshot()

    // 📑 タブ一覧を表示
    showTabOverview = true
  }
}
