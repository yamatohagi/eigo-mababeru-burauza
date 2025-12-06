//
//  SpeechService.swift
//  eigo-manaberu-burauza
//
//  音声読み上げ機能を提供するサービス
//

import AVFoundation

/// ========================================
/// 🔊 クラス名: SpeechService
/// 📌 目的: テキストの音声読み上げを管理
/// ========================================
// TypeScriptでいう:
//   class SpeechService {
//     speak(text: string, language: string): void
//   }
// nonisolated(unsafe) を使ってSendableの警告を回避（iOS専用なので問題なし）
class SpeechService: NSObject, AVSpeechSynthesizerDelegate {

  // 🔊 音声合成エンジン
  // nonisolated(unsafe): このクラスはMainActorで使用される前提
  nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()

  // 🔄 再生状態が変わった時のコールバック
  var onSpeakingChanged: ((Bool) -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔊 テキストを音声で読み上げ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// - Parameters:
  ///   - text: 読み上げるテキスト
  ///   - language: 言語コード（"en-US", "ja-JP"など）
  func speak(_ text: String, language: String) {
    // 🔇 マナーモードでも音声を再生するためのオーディオセッション設定（iOS専用）
    #if os(iOS)
      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        print("❌ オーディオセッション設定エラー: \(error)")
      }
    #endif

    // 🛑 前の読み上げを停止（連打防止）
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    let utterance = AVSpeechUtterance(string: text)

    // 🌐 言語を設定
    utterance.voice = AVSpeechSynthesisVoice(language: language)

    // 🎚️ 読み上げ速度（0.0〜1.0、0.5が標準）
    utterance.rate = 0.45

    // 🔊 音量（0.0〜1.0）
    utterance.volume = 1.0

    // 🎵 ピッチ（0.5〜2.0、1.0が標準）
    utterance.pitchMultiplier = 1.0

    // 読み上げ開始
    synthesizer.speak(utterance)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛑 読み上げを停止
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📡 AVSpeechSynthesizerDelegate
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
  {
    DispatchQueue.main.async {
      self.onSpeakingChanged?(false)
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
  {
    DispatchQueue.main.async {
      self.onSpeakingChanged?(false)
    }
  }
}
