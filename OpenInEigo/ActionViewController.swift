//
//  ActionViewController.swift
//  OpenInEigo
//
//  「英語ブラウザで開く」アクション
//

import UIKit
import UniformTypeIdentifiers

/// ========================================
/// 🧩 クラス名: ActionViewController
/// 📌 目的: 共有シートから直接アプリを開く（UIなし・即座に遷移）
/// ========================================
class ActionViewController: UIViewController {

  // 📱 初期化時に即座に処理開始（viewDidLoadより前）
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    // 初期化直後に処理開始
    DispatchQueue.main.async { [weak self] in
      self?.handleAction()
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    DispatchQueue.main.async { [weak self] in
      self?.handleAction()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // UIを完全に透明に（一瞬も見せない）
    view.isHidden = true
    view.alpha = 0
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 アクションを処理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func handleAction() {
    guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
      done()
      return
    }

    for extensionItem in extensionItems {
      guard let attachments = extensionItem.attachments else { continue }

      for attachment in attachments {
        // 🌐 URLの場合
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          attachment.loadItem(forTypeIdentifier: UTType.url.identifier) {
            [weak self] (item, error) in
            if let url = item as? URL {
              self?.openInMainApp(url)
            } else {
              self?.done()
            }
          }
          return
        }

        // 📝 テキストの場合
        if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
          attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) {
            [weak self] (item, error) in
            if let text = item as? String, let url = URL(string: text) {
              self?.openInMainApp(url)
            } else {
              self?.done()
            }
          }
          return
        }
      }
    }

    done()
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 メインアプリで開く
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func openInMainApp(_ url: URL) {
    // 📦 App Groupsに保存（バックアップ）
    if let userDefaults = UserDefaults(suiteName: "group.com.hagiyamato.eigobrowser") {
      userDefaults.set(url.absoluteString, forKey: "SharedURL")
      userDefaults.synchronize()
    }

    // 🔗 URLスキームを作成
    let encodedURL =
      url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    guard let appURL = URL(string: "eigobrowser://open?url=\(encodedURL)") else {
      done()
      return
    }

    // 📱 URLを開いてから完了（順序が重要）
    openURL(appURL)
    done()
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔓 URLを開く
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func openURL(_ url: URL) {
    // UIApplication.shared.open を使う
    guard
      let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared))
        as? UIApplication
    else {
      return
    }
    application.open(url, options: [:], completionHandler: nil)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ 完了
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private func done() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
