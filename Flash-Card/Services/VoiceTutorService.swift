import Foundation
import SwiftUI
import Combine
import AVFoundation
import Speech

@MainActor
class VoiceTutorService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var spokenText = ""
    @Published var isSpeaking = false
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        isSpeaking = true
        synthesizer.speak(utterance)
        
        // Wait for completion (simple poll or delegate could be used, for now a simple Task)
        Task {
            while synthesizer.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            isSpeaking = false
            completion()
        }
    }
    
    func startListening(completion: @escaping (String) -> Void) throws {
        // Cancel previous task if running
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create request") }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        spokenText = ""
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.spokenText = result.bestTranscription.formattedString
                if result.isFinal {
                    self.stopListening()
                    completion(self.spokenText)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isListening = false
    }
}
