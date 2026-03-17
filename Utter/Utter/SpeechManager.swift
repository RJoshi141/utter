//
//  SpeechManager.swift
//  Utter
//
//  Created by Ritika Joshi on 3/15/26.
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject {

    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var levels: [CGFloat] = Array(repeating: 0.15, count: 9)

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    
    
    private func normalizedLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.12 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.12 }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let boosted = CGFloat(rms) * 28

        return max(0.12, min(boosted, 1.0))
    }
    
    
    
    func requestPermissions() {

        SFSpeechRecognizer.requestAuthorization { _ in }

        AVAudioApplication.requestRecordPermission { _ in }    }

    
    
    
    func startRecording() throws {
        transcript = ""
        isRecording = true

        task?.cancel()
        task = nil

        request = SFSpeechAudioBufferRecognitionRequest()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        guard let request else { return }

        request.shouldReportPartialResults = true

        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil {
                self.stopRecording()
            }
        }

        let recordingFormat = inputNode.inputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)

            let level = self.normalizedLevel(from: buffer)

            DispatchQueue.main.async {
                self.levels.removeFirst()
                self.levels.append(level)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        task?.cancel()

        isRecording = false
        levels = Array(repeating: 0.15, count: 9)

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    
    
    
    func transcribeAudioFile(at url: URL, completion: @escaping (String?) -> Void) {
        transcript = ""

        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognizer unavailable")
            completion(nil)
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        task?.cancel()
        task = recognizer.recognitionTask(with: request) { result, error in
            if let result = result, result.isFinal {
                let finalTranscript = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    self.transcript = finalTranscript
                    completion(finalTranscript)
                }
                return
            }

            if let error = error {
                print("File transcription failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    
    
}
