//
//  SearchBar.swift
//  eigo-manaberu-burauza
//
//  Safari風の検索バー（URL入力・検索兼用）
//

import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

/// ========================================
/// 🧩 View名: SearchBar
/// 📌 目的: Safari風の検索バー（URL入力・検索兼用）
/// ========================================
struct SearchBar: View {
  // 🔗 入力テキスト（親と共有）
  @Binding var text: String
  // ⏳ ローディング中かどうか
  var isLoading: Bool
  // ⏎ Enter押下時のコールバック
  var onSubmit: () -> Void

  // 🎨 フォーカス状態
  @FocusState private var isFocused: Bool

  // 📝 テキスト選択状態（iOS 18+）
  // TypeScriptでいう: const [selection, setSelection] = useState<Range | null>(null)
  @State private var selection: TextSelection?

  var body: some View {
    HStack(spacing: 6) {
      // 🔍 検索アイコン or ローディング
      if isLoading {
        ProgressView()
          .scaleEffect(0.7)
          .frame(width: 16, height: 16)
      } else {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.gray)
          .font(.system(size: 14))
      }

      // 📝 テキストフィールド（iOS 18+の選択機能を使用）
      TextField("検索またはURLを入力", text: $text, selection: $selection)
        .textInputAutocapitalization(.never)  // 先頭大文字無効
        .keyboardType(.default)  // 🌐 日本語キーボードがデフォルト
        .autocorrectionDisabled(true)  // オートコレクト無効
        .focused($isFocused)
        .onSubmit {
          onSubmit()
          isFocused = false  // キーボードを閉じる
        }
        // 🎯 フォーカス時に全選択
        .onChange(of: isFocused) { _, newValue in
          if newValue && !text.isEmpty {
            // テキスト全体を選択
            selection = TextSelection(range: text.startIndex..<text.endIndex)
          }
        }

      // ✕ クリアボタン（テキストがある時のみ表示）
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.gray)
            .font(.system(size: 14))
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(UIColor.systemGray6))
    .cornerRadius(10)
  }
}
