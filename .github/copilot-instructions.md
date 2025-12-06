# Copilot Instructions for Swift/SwiftUI

GitHub Copilot に高品質な Swift コードを生成させるための指示セット。

---

## 🧑‍💻 ユーザーについて

- **Swift 初学者**（TypeScript 経験者）
- わかりにくい Swift の概念は **TypeScript での例も併記**して説明すること

---

## 🎯 基本方針

- **シンプルで小さく責務が明確な関数・View に分割**
- **日本語コメントで処理の意図（Why）を説明**
- **型安全を最優先**（Swift の型システムをフル活用）

---

## 🧱 コメントブロック（関数）

```swift
/// ========================================
/// 🔧 関数名: fetchUserData
/// 📌 目的: ユーザー情報を API から取得する
/// 📝 処理概要:
///   - URLSession で非同期リクエスト
///   - JSON をデコードして User 型で返す
/// ========================================
func fetchUserData() async throws -> User {
    // ...
}
```

---

## 🧩 コメントブロック（SwiftUI View）

```swift
/// ========================================
/// 🧩 View名: UserProfileView
/// 📌 目的: ユーザーのプロフィール画面を表示
/// 👀 状態:
///   - @State user: 表示するユーザー情報
///   - @State isLoading: ローディング状態
/// ========================================
struct UserProfileView: View {
    @State private var user: User?
    @State private var isLoading = false
    
    var body: some View {
        // ...
    }
}
```

---

## 📝 処理ブロックのコメント

```swift
// 🔍 入力値を正規化（空白を除去）
let trimmed = input.trimmingCharacters(in: .whitespaces)

// 🚀 API リクエスト送信
let response = try await apiClient.send(request)
```




## 🧭 SwiftUI 実装の基本指針

- **1 View = 1 役割**
- **表示ロジックとビジネスロジックは分離**
- **View が大きくなったら小さな View に分割**

---

## ✅ まとめ

- 小さく単機能の関数・View を書く
- コメントで目的（Why）を明記
- Swift 初学者向けに TypeScript 対応例を出す
- 型を厳密に使う



以下は例
ソースコードの記述に関しては何の意味がある？何のためにこのなんて言うんだろう。この記述が必要なのかちゃんとコメント書いてくれるようお願い


//
//  ContentView.swift
//  eigo-manaberu-burauza
//
//  Created by 萩 山登 on 2025/12/02.
//

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 import文
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: import { ... } from 'swiftui'
import SwiftUI  // SwiftUIフレームワーク（UIを作るための部品が入ってる）
import WebKit   // WebKitフレームワーク（ブラウザ機能を使うための部品）

/// ========================================
/// 🧩 View名: ContentView
/// 📌 目的: アプリのメイン画面
/// ========================================
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏗️ struct ContentView: View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: interface View { body: JSX.Element }
//                   const ContentView: React.FC = () => { ... }
//
// 「: View」は「このstructはViewプロトコルに従います」という宣言
// Viewプロトコルは「bodyプロパティを持つこと」を要求する
// → だからbodyを書かないとエラーになる
struct ContentView: View {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 @State について
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: const [selectedText, setSelectedText] = useState("")
  //
  // @State = 「この変数が変わったら画面を再描画してね」というマーク
  // private = このView内でしか使わない（外からアクセス不可）
  //
  // なぜ必要？ → 普通の変数だと値が変わっても画面が更新されない
  @State private var selectedText: String = ""

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 body について
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: return ( <div>...</div> )
  //
  // 「var body: some View」= このViewが実際に表示する中身
  // 「some View」= 「何かしらのView型を返す」という意味（型推論に任せる）
  var body: some View {

    // VStack = 縦に並べるコンテナ
    // TypeScriptでいう: <div style={{display: 'flex', flexDirection: 'column'}}>
    VStack {

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🌐 WebViewを表示
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // $selectedText の「$」は Binding を渡すという意味
      // TypeScriptでいう: <WebView selectedText={selectedText} setSelectedText={setSelectedText} />
      // ただしSwiftでは$をつけるだけで「値の読み書き両方」を渡せる
      WebView(selectedText: $selectedText)

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📝 選択テキスト表示エリア
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // TypeScriptでいう: {selectedText && <p>選択中: {selectedText}</p>}
      if !selectedText.isEmpty {
        Text("選択中: \(selectedText)")
          .padding()                          // 内側に余白
          .background(Color.gray.opacity(0.2)) // 背景色（薄いグレー）
          .cornerRadius(8)                     // 角を丸くする
      }
    }
  }
}

/// ========================================
/// 🧩 View名: WebView
/// 📌 目的: WKWebView（iOS標準ブラウザエンジン）をSwiftUIで使えるようにする
/// ========================================
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏗️ UIViewRepresentable について
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SwiftUIは新しいUI作成方法。でもブラウザ(WKWebView)は古いUIKit製。
// UIViewRepresentable = 「古いUIKitのViewをSwiftUIで使うためのアダプター」
//
// このプロトコルを使うと、以下の関数を実装する必要がある:
// - makeUIView()   → UIKitのViewを作って返す
// - updateUIView() → SwiftUIの状態が変わった時にUIKitのViewを更新する
// - makeCoordinator() → イベントを処理するヘルパークラスを作る（オプション）
struct WebView: UIViewRepresentable {

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔗 @Binding について
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: props として { selectedText, setSelectedText } を受け取る感じ
  //
  // @Binding = 「親から渡された状態への参照」
  // この変数を変更すると、親(ContentView)の@State selectedTextも変わる
  // → 親の画面も自動で再描画される
  //
  // なぜ@Stateじゃなく@Binding？
  // → @Stateは「自分で持つ状態」、@Bindingは「親から借りてる状態」
  @Binding var selectedText: String

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 makeUIView - UIKitのViewを作成
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: useEffect(() => { /* 初期化処理 */ }, [])
  //
  // この関数は画面が表示される時に1回だけ呼ばれる
  // 引数の「context」にはCoordinatorなどの情報が入ってる
  // 戻り値の「-> WKWebView」は「WKWebView型を返す」という意味
  func makeUIView(context: Context) -> WKWebView {

    // WKWebView() = ブラウザのインスタンスを作成
    let webView = WKWebView()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🎯 navigationDelegate について
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // TypeScriptでいう: webView.onNavigate = coordinator.handleNavigate
    //
    // delegate = 「イベントが起きた時に処理を任せる相手」
    // ページ読み込み完了とかのイベントをCoordinatorに通知する設定
    webView.navigationDelegate = context.coordinator

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🚀 初期ページを読み込み
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // if let = 「URLの作成に成功したら」という条件分岐
    // TypeScriptでいう: const url = new URL("..."); if (url) { ... }
    //
    // なぜif let？ → URL(string:)は失敗する可能性がある（不正なURLとか）
    // 失敗するとnilが返るので、nilじゃない時だけ実行する
    if let url = URL(string: "https://bbc.com") {
      webView.load(URLRequest(url: url))
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📱 JavaScriptをWebページに注入する設定
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // WKUserScript = 「ページに自動で実行させるJavaScript」
    //
    // source: 実行するJavaScriptコード
    // injectionTime: .atDocumentEnd = ページ読み込み完了後に実行
    // forMainFrameOnly: false = iframeの中でも実行する
    let script = WKUserScript(
      source: """
            // ページ内でテキスト選択が変わった時に発火するイベント
            document.addEventListener('selectionchange', function() {
                // 選択中のテキストを取得
                var text = window.getSelection().toString();
                if (text.length > 0) {
                    // Swift側に選択テキストを送信
                    // 'textSelected'という名前でメッセージを送る
                    window.webkit.messageHandlers.textSelected.postMessage(text);
                }
            });
        """,
      injectionTime: .atDocumentEnd,
      forMainFrameOnly: false
    )

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📨 JavaScript→Swift の通信設定
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // addUserScript = 上で作ったJavaScriptを登録
    // add(coordinator, name:) = "textSelected"というメッセージをcoordinatorで受け取る設定
    //
    // TypeScriptでいう:
    //   window.addEventListener('message', (e) => {
    //     if (e.data.type === 'textSelected') coordinator.handle(e.data)
    //   })
    webView.configuration.userContentController.addUserScript(script)
    webView.configuration.userContentController.add(context.coordinator, name: "textSelected")

    return webView
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 updateUIView - SwiftUIの状態変化時に呼ばれる
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう: useEffect(() => { /* 更新処理 */ }, [props])
  //
  // 親のStateが変わった時にUIKitのViewを更新する場所
  // 今回は特に何もしない（WebViewは自分で状態管理するので）
  func updateUIView(_ uiView: WKWebView, context: Context) {}

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 makeCoordinator - Coordinatorを作成
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Coordinatorは「イベントを処理するヘルパークラス」
  // なぜ必要？ → UIKitのdelegateパターンはクラスが必要だから
  // structのWebViewでは直接delegateになれないので、別クラスを作る
  func makeCoordinator() -> Coordinator {
    // Coordinator(self) = 「親(このWebView)への参照を持ったCoordinator」を作成
    Coordinator(self)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎭 Coordinator クラス
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TypeScriptでいう:
  //   class Coordinator implements WKNavigationDelegate, WKScriptMessageHandler {
  //     constructor(private parent: WebView) {}
  //   }
  //
  // NSObject = UIKitのクラスの基底クラス（delegateに必要）
  // WKNavigationDelegate = ページ遷移イベントを受け取るためのプロトコル
  // WKScriptMessageHandler = JavaScriptからのメッセージを受け取るためのプロトコル
  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    // parent = このCoordinatorを作った親のWebViewへの参照
    // これがないとselectedTextを更新できない
    var parent: WebView

    // 初期化時に親への参照を受け取る
    init(_ parent: WebView) {
      self.parent = parent
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📨 JavaScriptからメッセージを受信した時に呼ばれる
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // WKScriptMessageHandlerプロトコルで定義されてる関数
    // JavaScriptの window.webkit.messageHandlers.XXX.postMessage() で呼ばれる
    //
    // message.name = メッセージの名前（"textSelected"）
    // message.body = メッセージの中身（選択されたテキスト）
    func userContentController(
      _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
      // "textSelected"メッセージで、中身がString型の場合のみ処理
      // TypeScriptでいう: if (message.name === 'textSelected' && typeof message.body === 'string')
      if message.name == "textSelected", let text = message.body as? String {
        // 親のselectedTextを更新 → @Bindingなので親の@Stateも更新される → 画面再描画
        parent.selectedText = text
      }
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 👀 #Preview - Xcodeのプレビュー用
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: export const Preview = () => <ContentView />
// Xcodeの右側にリアルタイムプレビューを表示するための記述
#Preview {
  ContentView()
}
