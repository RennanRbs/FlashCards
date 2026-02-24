//
//  TTSService.swift
//  FlashCards
//

import AVFoundation
import Foundation

final class TTSService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, language: String = "pt-BR") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}
