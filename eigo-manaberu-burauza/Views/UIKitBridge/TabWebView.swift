//
//  TabWebView.swift
//  eigo-manaberu-burauza
//
//  Created by AI Assistant on 2025/12/05.
//

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import SwiftUI
import WebKit

/// ========================================
/// 🧩 View名: TabWebView
/// 📌 目的: 1つのタブのWKWebViewをSwiftUIで表示
/// ========================================
/// 責務:
/// - タブのWebViewをUIKitブリッジで表示
/// - 翻訳モードのJavaScript注入
/// - スクロールイベントの通知
struct TabWebView: UIViewRepresentable {
  // 📑 表示するタブ
  @ObservedObject var tab: BrowserTab

  // 🔗 親から渡される状態
  @Binding var selectedText: String
  @Binding var isTranslationMode: Bool

  // 🎯 このタブがアクティブかどうか
  var isActive: Bool

  // 📱 スクロールコールバック
  var onScroll: ((ScrollDirection) -> Void)?

  // 🗂️ タブマネージャー（新しいタブを開く時に使用）
  // target="_blank" のリンクをクリックした時に新しいタブを作成するために必要
  var tabManager: TabManager?

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 makeUIView - UIKitのViewを作成
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func makeUIView(context: Context) -> WKWebView {
    // 🔥 タブが既に持っているWebViewを返す（新規作成しない！）
    let webView = tab.webView

    // 📱 スクロールデリゲートを設定（Safari風バー非表示用）
    webView.scrollView.delegate = context.coordinator

    // 🎯 ナビゲーションデリゲートを設定
    webView.navigationDelegate = context.coordinator

    // 🔗 UIデリゲートを設定（target="_blank" リンク対応）
    // TypeScriptでいう: webView.onNewWindow = coordinator.handleNewWindow
    // _blankリンクがクリックされた時にCoordinatorが処理できるようになる
    webView.uiDelegate = context.coordinator

    // 📨 JavaScript→Swift の通信設定
    // 既に追加されている場合はスキップ
    let handlerName = "textSelected"
    let controller = webView.configuration.userContentController
    // 一度削除してから追加（重複防止）
    controller.removeScriptMessageHandler(forName: handlerName)
    controller.add(context.coordinator, name: handlerName)

    return webView
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 updateUIView - SwiftUIの状態変化時に呼ばれる
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func updateUIView(_ uiView: WKWebView, context: Context) {
    // 🔄 onScrollコールバックを更新
    context.coordinator.onScroll = onScroll

    if isTranslationMode {
      // 📖 翻訳モード: リンクを無効化 + テキスト選択有効化
      injectTranslationModeJS(uiView)
    } else {
      // 🌐 通常モード: 元の状態に復元
      removeTranslationModeJS(uiView)
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 makeCoordinator - Coordinatorを作成
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📖 翻訳モードのJavaScriptを注入
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func injectTranslationModeJS(_ webView: WKWebView) {
    let jsCode = """
        if (!window._translationModeEnabled) {
          window._translationModeEnabled = true;
          
          var style = document.createElement('style');
          style.id = 'translation-mode-style';
          style.textContent = `
            a, a * {
              -webkit-tap-highlight-color: transparent !important;
              -webkit-touch-callout: none !important;
              cursor: text !important;
            }
            a {
              display: inline !important;
              pointer-events: none !important;
            }
            a > * {
              display: inline !important;
            }
            body, body * {
              -webkit-user-select: text !important;
              user-select: text !important;
            }
          `;
          document.head.appendChild(style);
          
          window._originalHrefs = [];
          var links = document.querySelectorAll('a');
          links.forEach(function(link, index) {
            window._originalHrefs[index] = link.href;
            link.href = 'javascript:void(0)';
            link.setAttribute('draggable', 'false');
          });
          
          window._translationClickHandler = function(e) {
            var range = document.caretRangeFromPoint(e.clientX, e.clientY);
            if (range && range.startContainer.nodeType === Node.TEXT_NODE) {
              var textNode = range.startContainer;
              var text = textNode.textContent;
              var offset = range.startOffset;
              
              var start = offset;
              while (start > 0 && /[a-zA-Z0-9'-]/.test(text[start - 1])) {
                start--;
              }
              
              var end = offset;
              while (end < text.length && /[a-zA-Z0-9'-]/.test(text[end])) {
                end++;
              }
              
              if (start < end) {
                var wordRange = document.createRange();
                wordRange.setStart(textNode, start);
                wordRange.setEnd(textNode, end);
                
                var selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(wordRange);
                
                var selectedWord = text.substring(start, end);
                window.webkit.messageHandlers.textSelected.postMessage(selectedWord);
              }
            }
          };
          document.addEventListener('click', window._translationClickHandler);
          
          window._translationSelectionHandler = function() {
            var text = window.getSelection().toString();
            if (text.length > 0) {
              window.webkit.messageHandlers.textSelected.postMessage(text);
            }
          };
          document.addEventListener('selectionchange', window._translationSelectionHandler);
        }
      """
    webView.evaluateJavaScript(jsCode, completionHandler: nil)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🌐 翻訳モードのJavaScriptを削除
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func removeTranslationModeJS(_ webView: WKWebView) {
    let jsCode = """
        if (window._translationModeEnabled) {
          window._translationModeEnabled = false;
          
          var style = document.getElementById('translation-mode-style');
          if (style) style.remove();
          
          if (window._originalHrefs) {
            var links = document.querySelectorAll('a');
            links.forEach(function(link, index) {
              if (window._originalHrefs[index]) {
                link.href = window._originalHrefs[index];
              }
              link.removeAttribute('draggable');
            });
            window._originalHrefs = null;
          }
          
          if (window._translationClickHandler) {
            document.removeEventListener('click', window._translationClickHandler);
          }
          
          if (window._translationSelectionHandler) {
            document.removeEventListener('selectionchange', window._translationSelectionHandler);
          }
        }
      """
    webView.evaluateJavaScript(jsCode, completionHandler: nil)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎭 Coordinator クラス
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WKUIDelegate を追加 → target="_blank" リンクを処理できるようになる
  // TypeScriptでいう:
  //   class Coordinator implements WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate { ... }
  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate,
    WKUIDelegate
  {
    var parent: TabWebView

    // 📱 スクロールコールバック
    var onScroll: ((ScrollDirection) -> Void)?

    // 📱 スクロール関連
    var lastScrollY: CGFloat = 0
    let scrollThreshold: CGFloat = 10

    init(_ parent: TabWebView) {
      self.parent = parent
      self.onScroll = parent.onScroll
    }

    // 📨 JavaScriptからメッセージを受信
    func userContentController(
      _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
      if message.name == "textSelected", let text = message.body as? String {
        parent.selectedText = text
      }
    }

    // ✅ ページ読み込み完了
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      parent.tab.updateState()
    }

    // ⏳ ページ読み込み開始
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      DispatchQueue.main.async {
        self.parent.tab.isLoading = true
      }
    }

    // 📱 スクロール時に呼ばれる（Safari風バー非表示）
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      let currentY = scrollView.contentOffset.y
      let diff = currentY - lastScrollY

      // ページ最上部付近ではバーを表示
      if currentY <= 50 {
        onScroll?(.up)
        lastScrollY = currentY
        return
      }

      // スクロールダウン → バーを隠す
      if diff > scrollThreshold {
        onScroll?(.down)
        lastScrollY = currentY
      }
      // スクロールアップ → バーを表示
      else if diff < -scrollThreshold {
        onScroll?(.up)
        lastScrollY = currentY
      }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🔗 target="_blank" リンクを新しいタブで開く
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // WKUIDelegateのメソッド
    // TypeScriptでいう:
    //   handleNewWindow(url: string): WebView | null {
    //     tabManager.addTab(url);
    //     return null; // 新しいWebViewは返さない（自分でタブを管理するから）
    //   }
    //
    // なぜnilを返す？
    // → 新しいWKWebViewを返すと、WKWebViewが自分で管理しようとする
    // → 代わりにTabManagerで新しいタブを作成して、そこにURLを読み込む
    func webView(
      _ webView: WKWebView,
      createWebViewWith configuration: WKWebViewConfiguration,
      for navigationAction: WKNavigationAction,
      windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
      // 🔍 リンク先のURLを取得
      guard let url = navigationAction.request.url else {
        return nil
      }

      // 🗂️ TabManagerがあれば新しいタブで開く
      if let tabManager = parent.tabManager {
        // 📱 メインスレッドでUIを更新
        DispatchQueue.main.async {
          // ➕ 新しいタブを追加してURLを読み込み
          tabManager.addTab(url: url.absoluteString)
        }
      } else {
        // TabManagerがない場合は現在のタブで開く（フォールバック）
        webView.load(navigationAction.request)
      }

      // 🔥 nilを返すことで、WKWebViewに新しいウィンドウを作らせない
      // 代わりにTabManagerで新しいタブを管理する
      return nil
    }
  }
}
