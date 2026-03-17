//
//  ContentView.swift
//  UtterWatch Watch App
//
//  Created by Ritika Joshi on 3/14/26.
//

import SwiftUI
import WatchKit
import Combine
import WatchConnectivity

enum CaptureState {
    case idle
    case recording
    case review
    case processing
    case confirmed
}

struct ContentView: View {
    @State private var hasStarted = false

    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var state: CaptureState = .idle
    @State private var pulse = false
    @State private var isPressing = false
    @State private var pressStartDate: Date?

    @State private var recordingStart: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var liveTranscript = ""
    @State private var capturedTranscript = ""

    @StateObject private var audioRecorder = WatchAudioRecorder()
    @State private var returnedCategory = "memo"
    @State private var returnedTranscript = ""

    private let brandYellow = Color(hex: "FFD15B")
    private let darkSurface = Color(hex: "1A1A1A")
    private let secondaryText = Color(hex: "9A9A9A")

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !hasStarted {
                introView
            } else {
                switch state {
                case .idle:       idleView
                case .recording:  recordingView
                case .review:     reviewView
                case .processing: processingView
                case .confirmed:  confirmedView
                }
            }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Title
                VStack(alignment: .leading, spacing: 3) {
                    Text("Utter")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Voice notes from your wrist.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(brandYellow)
                }
                
                Text("Capture thoughts the moment they happen — no typing, no unlocking your phone.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                // Steps
                VStack(alignment: .leading, spacing: 10) {
                    introStep(icon: "waveform",  text: "Hold to record a thought")
                    introStep(icon: "iphone",    text: "Send it to your iPhone")
                    introStep(icon: "tray.fill", text: "It's transcribed and sorted")
                }

                Button {
                    hasStarted = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pulse = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(brandYellow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func introStep(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(brandYellow)
                .frame(width: 22, alignment: .center)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func categoryPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.85)))
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 12) {
            if isPressing {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 3) {
                        ForEach(Array(audioRecorder.levels.enumerated()), id: \.offset) { _, level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(brandYellow)
                                .frame(width: 4, height: max(10, 40 * level))
                        }
                    }
                    .frame(height: 44)

                    Text(timerString)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(brandYellow)
                        .monospacedDigit()

                    Text("Release to save")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                // Mic with pulsating rings — animate the whole ZStack
                ZStack {
                    Circle()
                        .fill(brandYellow.opacity(0.18))
                        .frame(width: 84, height: 84)

                    Circle()
                        .fill(brandYellow.opacity(0.07))
                        .frame(width: 66, height: 66)

                    Circle()
                        .fill(Color(hex: "0B0B0B"))
                        .frame(width: 50, height: 50)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.07), lineWidth: 1))

                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(brandYellow)
                }
                .scaleEffect(pulse ? 1.10 : 1.0)
                .animation(
                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: pulse
                )
                .onAppear {
                    // Small delay ensures the view is fully mounted before animating
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        pulse = true
                    }
                }

                Text("Hold to speak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        pressStartDate = Date()
                        recordingStart = Date()
                        WKInterfaceDevice.current().play(.start)
                        do { try audioRecorder.startRecording() }
                        catch { print("Watch recording failed: \(error.localizedDescription)") }
                    }
                }
                .onEnded { _ in
                    let heldLongEnough: Bool
                    if let pressStartDate {
                        heldLongEnough = Date().timeIntervalSince(pressStartDate) >= 0.35
                    } else {
                        heldLongEnough = false
                    }

                    isPressing = false
                    self.pressStartDate = nil
                    recordingDuration = 0

                    if heldLongEnough {
                        audioRecorder.stopRecording()
                        state = .review
                    } else {
                        audioRecorder.stopRecording()
                    }
                }
        )
        .onReceive(timer) { _ in
            if isPressing, let recordingStart {
                recordingDuration = Date().timeIntervalSince(recordingStart)
            }
        }
    }

    // MARK: - Recording (alias)

    private var recordingView: some View {
        idleView
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("Review")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Send to iPhone?")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(secondaryText)
            }

            HStack(spacing: 14) {
                // Play with progress ring flush on border
                Button {
                    audioRecorder.playLastRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(darkSurface)
                            .frame(width: 46, height: 46)

                        Circle()
                            .strokeBorder(brandYellow.opacity(0.25), lineWidth: 2)
                            .frame(width: 46, height: 46)

                        Circle()
                            .trim(from: 0, to: audioRecorder.playbackProgress)
                            .stroke(brandYellow, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 46, height: 46)

                        Image(systemName: audioRecorder.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(brandYellow)
                    }
                }
                .buttonStyle(.plain)
                .animation(nil, value: audioRecorder.isPlaying)

                // Trash
                Button {
                    audioRecorder.deleteLastRecording()
                    state = .idle
                    pulse = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { pulse = true }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Circle()
                            .strokeBorder(Color.red.opacity(0.35), lineWidth: 2)
                            .frame(width: 46, height: 46)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)

                // Send
                Button {
                    if let url = audioRecorder.lastRecordingURL {
                        connectivityManager.sendAudioFile(url)
                    }
                    state = .processing
                } label: {
                    ZStack {
                        Circle()
                            .fill(brandYellow)
                            .frame(width: 46, height: 46)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(brandYellow)
                .scaleEffect(1.3)

            Text("Syncing")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Sending to iPhone…")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                returnedCategory = "memo"
                returnedTranscript = "Ready to sync"
                state = .confirmed
            }
        }
    }

    // MARK: - Confirmed — tap anywhere to go back

    private var confirmedView: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(brandYellow)
                    .frame(width: 48, height: 48)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
            }

            Text("Sent to iPhone")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("Tap to record again")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            state = .idle
            pulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { pulse = true }
        }
        .onAppear {
            WKInterfaceDevice.current().play(.success)
        }
    }

    // MARK: - Helpers

    private var timerString: String {
        let seconds = Int(recordingDuration)
        return String(format: "00:%02d", seconds)
    }
}
