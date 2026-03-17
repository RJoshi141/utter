//
//  WatchAudioRecorder.swift
//  Utter
//
//  Created by Ritika Joshi on 3/15/26.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

final class WatchAudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var levels: [CGFloat] = Array(repeating: 0.15, count: 9)

    private var audioRecorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isPlaying = false
    
    @Published var playbackProgress: Double = 0
    private var progressTimer: Timer?
    
    func playLastRecording() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            return
        }

        guard let url = lastRecordingURL else {
            print("No recording URL to play")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            if audioPlayer == nil || audioPlayer?.url != url {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
            }

            let didPlay = audioPlayer?.play() ?? false
            isPlaying = didPlay

            if didPlay {
                startProgressUpdates()
            }
            print("Attempted playback:", didPlay, "for file:", url.lastPathComponent)
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    func deleteLastRecording() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        guard let url = lastRecordingURL else { return }

        do {
            try FileManager.default.removeItem(at: url)
            lastRecordingURL = nil
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }
    
    
    
    
    

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("utter-\(UUID().uuidString).m4a")

        print("Recording saved at:", url.path)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        recorder.record()

        audioRecorder = recorder
        lastRecordingURL = url
        isRecording = true

        startMetering()
    }

    func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil

        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        levels = Array(repeating: 0.15, count: 9)

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate watch audio session: \(error.localizedDescription)")
        }
    }

    private func startMetering() {
        meterTimer?.invalidate()

        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder, recorder.isRecording else { return }

            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)

            let normalized = self.normalizePower(power)

            DispatchQueue.main.async {
                self.levels.removeFirst()
                self.levels.append(normalized)
            }
        }
    }

    private func normalizePower(_ power: Float) -> CGFloat {
        let minDb: Float = -50
        if power <= minDb { return 0.15 }
        if power >= 0 { return 1.0 }

        let value = (power - minDb) / -minDb
        return CGFloat(max(0.15, value))
    }
    
    
    
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playbackProgress = 0
        }

        progressTimer?.invalidate()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
        print("Playback decode error:", error?.localizedDescription ?? "none")
    }
    
    
    
    
    private func startProgressUpdates() {
        progressTimer?.invalidate()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = self.audioPlayer else { return }

            DispatchQueue.main.async {
                self.playbackProgress = player.duration > 0
                    ? player.currentTime / player.duration
                    : 0
            }
        }
    }
    
    
    
}
