//
//  TranslationSheetView.swift
//  eigo-manaberu-burauza
//
//  翻訳結果を表示する下からスライドするシート
//

import Inject
import SwiftUI
import UIKit  // 📋 SelectableTextView用

/// ========================================
/// 🧩 View名: TranslationSheetView
/// 📌 目的: 翻訳結果を表示する下からスライドするシート
/// ========================================
struct TranslationSheetView: View {
  // 🔥 Hot Reload用
  @ObserveInjection var inject

  // 表示するデータ
  let selectedText: String
  let translatedText: String
  let dictionaryInfo: String
  let isLoadingDictionary: Bool
  let isSpeaking: Bool
  let contextExplanation: String
  @Binding var isExplanationExpanded: Bool
  let isLoadingTranslation: Bool
  let isLoadingContext: Bool
  let errorMessage: String?

  // 📏 シートの現在の高さ
  @Binding var sheetDetent: PresentationDetent

  // 💬 チャット機能
  let chatMessages: [ChatMessage]
  @Binding var chatInput: String
  let isLoadingChat: Bool
  let onSendChat: () -> Void

  // アクション
  let onExplain: () -> Void
  let onSpeak: () -> Void

  // 📊 ミニバー状態かどうか
  private var isMinimized: Bool {
    sheetDetent == .height(75)
  }

  var body: some View {
    // フルシートのみ表示（ミニバーはBottomBarに移動）
    fullSheetView
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📏 ミニバー（タップで展開）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private var miniBarView: some View {
    HStack {
      if selectedText.isEmpty {
        Text("テキストを選択してください")
          .font(.subheadline)
          .foregroundColor(.gray)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text(selectedText)
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(1)
            .foregroundColor(.primary)

          if isLoadingTranslation {
            HStack(spacing: 4) {
              ProgressView()
                .scaleEffect(0.5)
              Text("翻訳中...")
                .font(.subheadline)
                .foregroundColor(.gray)
            }
          } else if !translatedText.isEmpty {
            Text(translatedText)
              .font(.subheadline)
              .foregroundColor(.blue)
              .lineLimit(1)
          }
        }
      }

      Spacer()

      if !selectedText.isEmpty {
        Button(action: onSpeak) {
          Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
            .font(.system(size: 22))
            .foregroundColor(isSpeaking ? .orange : .purple)
            .padding(8)
        }
        .buttonStyle(BorderlessButtonStyle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 18)
    .padding(.bottom, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        sheetDetent = .medium
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📋 通常のシート内容
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  private var fullSheetView: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // 📝 選択テキスト
          VStack(alignment: .leading, spacing: 4) {
            Text("📖 選択テキスト")
              .font(.caption)
              .foregroundColor(.gray)
            SelectableTextView(
              text: selectedText,
              font: .boldSystemFont(ofSize: 17),
              textColor: .label
            )
          }

          Divider()

          // 🇯🇵 翻訳結果
          VStack(alignment: .leading, spacing: 4) {
            Text("🇯🇵 翻訳")
              .font(.caption)
              .foregroundColor(.blue)

            if isLoadingTranslation {
              HStack {
                ProgressView()
                  .scaleEffect(0.7)
                Text("翻訳中...")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
            } else if !translatedText.isEmpty {
              SelectableTextView(
                text: translatedText,
                font: .systemFont(ofSize: 17),
                textColor: .label
              )
            }
          }

          // 📚 辞書（単語っぽい場合のみ表示）
          if !selectedText.contains(" ") && selectedText.count <= 30 {
            Divider()

            VStack(alignment: .leading, spacing: 4) {
              Text("📚 辞書")
                .font(.caption)
                .foregroundColor(.orange)

              if isLoadingDictionary {
                HStack {
                  ProgressView()
                    .scaleEffect(0.7)
                  Text("辞書を検索中...")
                    .font(.caption)
                    .foregroundColor(.gray)
                }
              } else if !dictionaryInfo.isEmpty {
                SelectableTextView(
                  text: dictionaryInfo,
                  font: .systemFont(ofSize: 17),
                  textColor: .label
                )
              }
            }
          }

          Divider()

          // 🤖 AI解説
          VStack(alignment: .leading, spacing: 8) {
            Text("🤖 AI解説")
              .font(.caption)
              .foregroundColor(.green)

            if isLoadingContext {
              HStack(spacing: 8) {
                ProgressView()
                  .scaleEffect(0.8)
                Text("解説を生成中...")
                  .font(.subheadline)
                  .foregroundColor(.gray)
              }
            } else if !contextExplanation.isEmpty {
              SelectableTextView(
                text: contextExplanation,
                font: .systemFont(ofSize: 17),
                textColor: .label
              )
            } else {
              Text("モーダルを開くと自動で解説が始まります")
                .font(.subheadline)
                .foregroundColor(.gray)
            }

            if !contextExplanation.isEmpty && !isLoadingContext {
              Button(action: onExplain) {
                HStack(spacing: 4) {
                  Image(systemName: "arrow.clockwise")
                  Text("再生成")
                }
                .font(.caption)
                .foregroundColor(.blue)
              }
              .padding(.top, 4)
            }
          }

          // 💬 チャットセクション
          if !contextExplanation.isEmpty {
            Divider()

            VStack(alignment: .leading, spacing: 12) {
              Text("💬 追加で質問する")
                .font(.caption)
                .foregroundColor(.purple)

              // チャット履歴
              ForEach(chatMessages) { message in
                if message.isUser {
                  // 👤 ユーザーのメッセージ（右寄せ）
                  HStack {
                    Spacer(minLength: 60)  // 📏 左に余白を確保
                    SelectableTextView(
                      text: message.content,
                      font: .systemFont(ofSize: 15),
                      textColor: .label
                    )
                    .padding(10)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                  }
                } else {
                  // 🤖 AIのメッセージ（左寄せ）
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("🤖")
                        .font(.caption)
                      SelectableTextView(
                        text: message.content,
                        font: .systemFont(ofSize: 15),
                        textColor: .label
                      )
                      .padding(10)
                      .background(Color.gray.opacity(0.1))
                      .cornerRadius(12)
                    }
                    Spacer(minLength: 60)  // 📏 右に余白を確保
                  }
                }
              }

              // ローディング表示
              if isLoadingChat {
                HStack(spacing: 8) {
                  ProgressView()
                    .scaleEffect(0.7)
                  Text("回答を生成中...")
                    .font(.caption)
                    .foregroundColor(.gray)
                }
              }

              // 入力欄（丸いカスタムスタイル）
              HStack(spacing: 8) {
                TextField("質問を入力...", text: $chatInput)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .background(Color(.systemGray6))
                  .clipShape(Capsule())
                  .submitLabel(.send)
                  .onSubmit {
                    onSendChat()
                  }
                  .toolbar {
                    // ⌨️ キーボードの上に「完了」ボタン
                    ToolbarItemGroup(placement: .keyboard) {
                      Spacer()
                      Button("閉じる") {
                        // キーボードを閉じる
                        UIApplication.shared.sendAction(
                          #selector(UIResponder.resignFirstResponder),
                          to: nil, from: nil, for: nil
                        )
                      }
                    }
                  }

                Button(action: onSendChat) {
                  Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(chatInput.isEmpty ? .gray : .white)
                    .padding(10)
                    .background(chatInput.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .clipShape(Circle())
                }
                .disabled(chatInput.isEmpty || isLoadingChat)
              }

              // 質問例
              if chatMessages.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                  Text("質問例:")
                    .font(.caption2)
                    .foregroundColor(.gray)

                  ForEach(["この文法をもっと詳しく", "他の例文を教えて", "似た表現は？"], id: \.self) { example in
                    Button(action: {
                      chatInput = example
                      onSendChat()  // 💬 タップしたらそのまま送信
                    }) {
                      Text(example)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                  }
                }
                .padding(.top, 4)
              }
            }
          }

          if let error = errorMessage {
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
          }

          Spacer()
        }
        .padding()
      }
      .navigationTitle(selectedText.isEmpty ? "翻訳" : selectedText)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: onSpeak) {
            Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
              .font(.system(size: 18))
              .foregroundColor(isSpeaking ? .orange : .purple)
          }
        }
      }
    }
    .navigationViewStyle(.stack)
    .background(Color.clear)
    .enableInjection()
  }
}

/// ========================================
/// 🧩 View名: SpeakingWaveView
/// 📌 目的: 音声再生中のアニメーション波形を表示
/// ========================================
struct SpeakingWaveView: View {
  @State private var isAnimating = false

  var body: some View {
    HStack(spacing: 2) {
      ForEach(0..<3, id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.white)
          .frame(width: 3, height: isAnimating ? 14 : 6)
          .animation(
            Animation
              .easeInOut(duration: 0.4)
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.15),
            value: isAnimating
          )
      }
    }
    .onAppear {
      isAnimating = true
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📋 SelectableTextView - 部分選択可能なテキスト
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TypeScriptでいう: UITextViewをラップしたReactコンポーネント
// SwiftUIのTextでは部分選択ができないため、UIKitのUITextViewを使用
// - 編集不可（isEditable = false）
// - 選択可能（isSelectable = true）で部分選択＆コピーが可能
// - タップで単語選択が可能
struct SelectableTextView: UIViewRepresentable {
  let text: String
  var font: UIFont = .systemFont(ofSize: 15)
  var textColor: UIColor = .label

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.isEditable = false  // 📝 編集不可
    textView.isSelectable = true  // ✅ 選択可能（部分選択OK）
    textView.isScrollEnabled = false  // スクロールはScrollViewに任せる
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.backgroundColor = .clear
    textView.font = font
    textView.textColor = textColor
    // 📏 幅に合わせて自動リサイズ
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    // URL自動検出
    textView.dataDetectorTypes = .link
    textView.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue
    ]

    // 👆 タップで単語選択できるようにジェスチャーを追加
    let tapGesture = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    textView.addGestureRecognizer(tapGesture)

    return textView
  }

  func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.text = text
    uiView.font = font
    uiView.textColor = textColor
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  // 📐 サイズ計算（親の幅に収まるように）
  func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
    guard let width = proposal.width, width > 0 else { return nil }
    let targetSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
    let fittingSize = uiView.sizeThatFits(targetSize)
    return CGSize(width: width, height: fittingSize.height)
  }

  // 🎯 Coordinator - タップジェスチャーを処理
  class Coordinator: NSObject, UIEditMenuInteractionDelegate {
    weak var textView: UITextView?
    var editMenuInteraction: UIEditMenuInteraction?

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let textView = gesture.view as? UITextView else { return }
      self.textView = textView

      let location = gesture.location(in: textView)

      // タップ位置の文字インデックスを取得
      guard let position = textView.closestPosition(to: location) else { return }

      // タップ位置の単語範囲を取得
      if let wordRange = textView.tokenizer.rangeEnclosingPosition(
        position,
        with: .word,
        inDirection: UITextDirection(rawValue: UITextLayoutDirection.right.rawValue)
      ) {
        // 単語を選択
        textView.selectedTextRange = wordRange

        // 選択メニューを表示
        textView.becomeFirstResponder()

        // UIEditMenuInteractionでメニューを表示
        if editMenuInteraction == nil {
          editMenuInteraction = UIEditMenuInteraction(delegate: self)
          textView.addInteraction(editMenuInteraction!)
        }

        // 選択範囲の矩形を取得してメニュー表示
        if let selectionRect = textView.selectedTextRange.flatMap({ textView.firstRect(for: $0) }) {
          let config = UIEditMenuConfiguration(
            identifier: nil, sourcePoint: CGPoint(x: selectionRect.midX, y: selectionRect.minY))
          editMenuInteraction?.presentEditMenu(with: config)
        }
      }
    }

    // UIEditMenuInteractionDelegate - メニュー内容をカスタマイズ可能
    func editMenuInteraction(
      _ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration,
      suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
      // デフォルトのコピー等のメニューを返す
      return UIMenu(children: suggestedActions)
    }
  }
}
