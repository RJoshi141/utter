//
//  ContentView.swift
//  Utter
//
//  Created by Ritika Joshi on 3/14/26.
//

import SwiftUI

// MARK: - Category Detail Screen

struct CategoryDetailView: View {
    let category: String
    @Binding var memos: [VoiceMemo]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let darkBackground = Color(hex: "0B0B0B")
    private let darkCard = Color(hex: "171717")
    private let secondaryText = Color(hex: "9A9A9A")
    private let brandYellow = Color(hex: "FFD15B")

    private func categoryColor(for cat: String) -> Color {
        switch cat {
        case "todo":     return .green
        case "reminder": return .orange
        case "idea":     return .purple
        case "note":     return .blue
        default:         return .gray
        }
    }

    private func categoryIcon(for cat: String) -> String {
        switch cat {
        case "todo":     return "checkmark.circle.fill"
        case "reminder": return "bell.fill"
        case "idea":     return "lightbulb.fill"
        case "note":     return "note.text"
        default:         return "tray.fill"
        }
    }

    private var items: [VoiceMemo] {
        memos.filter { $0.category == category }
    }

    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(categoryColor(for: category))
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(category.capitalized)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(items.count) \(items.count == 1 ? "note" : "notes")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        Spacer()

                        let doneCount = items.filter { $0.isDone }.count
                        if doneCount > 0 {
                            Text("\(doneCount) done")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.white.opacity(0.22)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Inbox")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(brandYellow)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)

                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(secondaryText)
                        Text("Nothing here yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(secondaryText)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, memo in
                                let isDone = memo.isDone

                                HStack(alignment: .top, spacing: 14) {
                                    Button {
                                        if let idx = memos.firstIndex(where: { $0.id == memo.id }) {
                                            memos[idx].isDone.toggle()
                                            onSave()
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .strokeBorder(
                                                    isDone ? categoryColor(for: category) : Color.white.opacity(0.25),
                                                    lineWidth: 1.5
                                                )
                                                .frame(width: 24, height: 24)
                                            if isDone {
                                                Circle()
                                                    .fill(categoryColor(for: category))
                                                    .frame(width: 24, height: 24)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(memo.text)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(isDone ? .white.opacity(0.35) : .white)
                                            .strikethrough(isDone, color: .white.opacity(0.35))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(memo.date, style: .time)
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
                                    }

                                    Button(role: .destructive) {
                                        withAnimation {
                                            memos.removeAll { $0.id == memo.id }
                                            onSave()
                                        }
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)

                                if index < items.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.horizontal, 18)
                                }
                            }
                        }
                        .background(darkCard)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    @EnvironmentObject var connectivityManager: PhoneConnectivityManager
    @StateObject private var speechManager = SpeechManager()
    @State private var memos: [VoiceMemo] = []
    @State private var lastImportedWatchFile = ""

    @State private var micPulse = false
    @State private var showReview = false
    @State private var draftTranscript = ""
    @State private var showInbox = false
    @State private var draftCategory = "note"
    @State private var hasStarted = false

    private let brandYellow = Color(hex: "FFD15B")
    private let darkBackground = Color(hex: "0B0B0B")
    private let darkCard = Color(hex: "171717")
    private let darkSurface = Color(hex: "1F1F1F")
    private let secondaryText = Color(hex: "9A9A9A")

    private func categoryCardBg(for category: String) -> Color {
        switch category {
        case "todo":     return Color(hex: "1a3326")
        case "reminder": return Color(hex: "2e1f0a")
        case "idea":     return Color(hex: "1e1630")
        case "note":     return Color(hex: "0d1f35")
        default:         return Color(hex: "1F1F1F")
        }
    }

    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            if !hasStarted { mobileIntroView } else { mainAppView }
        }
        .onAppear {
            speechManager.requestPermissions()
            loadMemos()
        }
        .sheet(isPresented: $showReview) { reviewSheet }
        .sheet(isPresented: $showInbox) { inboxSheet }
    }

    // MARK: - Main App View (Redesigned)

    private var mainAppView: some View {
        VStack(spacing: 0) {

            // Top bar
            HStack {
                Text("Utter")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button { showInbox = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.full.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Inbox")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(brandYellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(darkSurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)

            Spacer()

            // Mic + transcript area
            VStack(spacing: 20) {

                // Mic button
                VStack(spacing: 14) {
                    ZStack {
                       
                        
                        
                        Circle()
                            .fill(brandYellow.opacity(0.08))
                                .frame(width: 160, height: 160)

                            Circle()
                                .fill(brandYellow.opacity(0.05))
                                .frame(width: 130, height: 130)

                            Circle()
                                .fill(Color(hex: "0B0B0B"))
                                .frame(width: 96, height: 96)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                )

                        if speechManager.isRecording {
                            HStack(alignment: .center, spacing: 3) {
                                ForEach(Array(speechManager.levels.enumerated()), id: \.offset) { _, level in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(brandYellow)
                                        .frame(width: 3, height: max(8, 32 * level))
                                }
                            }
                            .frame(width: 60, height: 36)
                            .animation(.easeOut(duration: 0.12), value: speechManager.levels)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(brandYellow)
                        }
                    }
                    .scaleEffect(micPulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: micPulse)
                    .onAppear { micPulse = true }

                    VStack(spacing: 4) {
                        Text(speechManager.isRecording ? "Recording… release to save" : "Hold to record")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))

                        if !speechManager.isRecording {
                            Text("or import from Apple Watch below")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !speechManager.isRecording {
                                do { try speechManager.startRecording() }
                                catch { print("Failed to start recording: \(error.localizedDescription)") }
                            }
                        }
                        .onEnded { _ in
                            if speechManager.isRecording {
                                speechManager.stopRecording()
                                if !speechManager.transcript.isEmpty {
                                    draftTranscript = speechManager.transcript
                                    draftCategory = detectedCategory(for: speechManager.transcript)
                                }
                            }
                        }
                )

                // Transcript card (shown after recording)
                if !speechManager.transcript.isEmpty && !speechManager.isRecording {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(speechManager.transcript)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: categoryIcon(for: classifiedCategory))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(classifiedCategory.capitalized)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(categoryColor(for: classifiedCategory)))

                            Spacer()

                            Button {
                                draftTranscript = speechManager.transcript
                                draftCategory = classifiedCategory
                                showReview = true
                            } label: {
                                Text("Review")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(brandYellow)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(darkCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Bottom actions
            VStack(spacing: 10) {

                // Watch import button
                Button {
                    guard let watchFileURL = latestWatchRecordingURL() else {
                        print("Could not find latest watch recording")
                        return
                    }
                    lastImportedWatchFile = watchFileURL.lastPathComponent
                    speechManager.transcribeAudioFile(at: watchFileURL) { finalTranscript in
                        guard let finalTranscript, !finalTranscript.isEmpty else { return }
                        draftTranscript = finalTranscript
                        draftCategory = detectedCategory(for: finalTranscript)
                        speechManager.transcript = finalTranscript
                        showReview = true
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                        
                            Image(systemName: "applewatch")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(brandYellow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import from Apple Watch")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(lastImportedWatchFile.isEmpty ? "Transcribe latest recording" : "Last: \(lastImportedWatchFile.prefix(20))…")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(darkCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Intro View

    private var mobileIntroView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        
                        Text("Utter")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text("Voice capture for Apple Watch & iPhone.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(brandYellow)

                    Text("Record quick thoughts on your wrist. Transcribe and organize them on your phone.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("How it works")

                    VStack(alignment: .leading, spacing: 20) {
                        introStep(icon: "applewatch",     title: "Record on Apple Watch",  desc: "Hold to record, release to stop. Review the clip before saving.")
                        introStep(icon: "waveform",       title: "Transcribe on iPhone",   desc: "Import your latest watch recording and convert it to text.")
                        introStep(icon: "tray.full.fill", title: "Save to your inbox",     desc: "Confirm the category and it lands in the right bucket.")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Categories")

                    HStack(spacing: 8) {
                        ForEach(["todo", "reminder", "idea", "note"], id: \.self) { cat in
                            HStack(spacing: 6) {
                                Image(systemName: categoryIcon(for: cat))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(cat.capitalized)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(categoryColor(for: cat)))
                        }
                    }
                }

                Button { hasStarted = true } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brandYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)
            .padding(.bottom, 40)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(secondaryText)
            .kerning(1.0)
    }

    private func introStep(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(brandYellow)
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }

    private func introCategoryCard(category: String, icon: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(categoryColor(for: category).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(categoryColor(for: category))
            }
            Text(category.capitalized)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(categoryColor(for: category))
            Text(desc)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(categoryColor(for: category).opacity(0.6))
                .fixedSize(horizontal: false, vertical: true).lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(categoryCardBg(for: category))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(categoryColor(for: category).opacity(0.15), lineWidth: 1))
    }

    // MARK: - Inbox Sheet

    private var inboxSheet: some View {
        NavigationStack {
            ZStack {
                darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Inbox")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(memos.count) total")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                    if groupedMemos.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "tray").font(.system(size: 40, weight: .light)).foregroundStyle(secondaryText)
                            Text("Your inbox is empty").font(.system(size: 16, weight: .medium)).foregroundStyle(secondaryText)
                            Text("Record something to get started.").font(.system(size: 14)).foregroundStyle(secondaryText.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(groupedMemos, id: \.category) { group in
                                    NavigationLink(destination:
                                        CategoryDetailView(category: group.category, memos: $memos, onSave: saveMemos)
                                    ) {
                                        inboxCategoryCard(group: group)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func inboxCategoryCard(group: (category: String, items: [VoiceMemo])) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(categoryColor(for: group.category))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: categoryIcon(for: group.category))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(group.category.capitalized)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Text("\(group.items.count) \(group.items.count == 1 ? "note" : "notes")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))

                        let doneCount = group.items.filter { $0.isDone }.count
                        if doneCount > 0 {
                            Circle().fill(.white.opacity(0.4)).frame(width: 4, height: 4)
                            Text("\(doneCount) completed")
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(.white.opacity(0.22)))
                        }
                    }
                }

                Spacer()

                ZStack {
                    Circle().fill(.white.opacity(0.2)).frame(width: 36, height: 36)
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    // MARK: - Review Sheet

    private var reviewSheet: some View {
        ZStack {
            darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Edit category before saving.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)

                // Transcript
                Text(draftTranscript)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                // Category picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("CATEGORY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryText)
                        .kerning(1.0)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryOption(title: "todo")
                            categoryOption(title: "reminder")
                            categoryOption(title: "idea")
                            categoryOption(title: "note")
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        draftTranscript = ""; draftCategory = "note"; speechManager.transcript = ""
                        showReview = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Discard")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        let memo = VoiceMemo(text: draftTranscript, category: draftCategory, date: Date())
                        memos.insert(memo, at: 0); saveMemos()
                        draftTranscript = ""; draftCategory = "note"; speechManager.transcript = ""
                        showReview = false
                    } label: {
                        HStack(spacing: 8) {
                            Text("Save")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brandYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Helpers

    private var classifiedCategory: String {
        speechManager.transcript.isEmpty ? "none" : detectedCategory(for: speechManager.transcript)
    }

    private var groupedMemos: [(category: String, items: [VoiceMemo])] {
        ["todo", "reminder", "idea", "note"].compactMap { cat in
            let items = memos.filter { $0.category == cat }
            return items.isEmpty ? nil : (category: cat, items: items)
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "todo":     return .green
        case "reminder": return .orange
        case "idea":     return .purple
        case "note":     return .blue
        default:         return .gray
        }
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "todo":     return "checkmark.circle.fill"
        case "reminder": return "bell.fill"
        case "idea":     return "lightbulb.fill"
        case "note":     return "note.text"
        default:         return "tray.fill"
        }
    }

    private func latestWatchRecordingURL() -> URL? {
        let simulatorRoot = URL(fileURLWithPath: "/Users/ritikajoshi/Library/Developer/CoreSimulator/Devices/6DDAA3A3-9736-4604-BF7D-50785A8FB45C")
        guard let enumerator = FileManager.default.enumerator(at: simulatorRoot, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return nil }
        var matches: [URL] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "m4a", fileURL.lastPathComponent.hasPrefix("utter-") else { continue }
            matches.append(fileURL)
        }
        return matches.max {
            let l = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let r = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return l < r
        }
    }

    private let memosKey = "utter_saved_memos"

    private func saveMemos() {
        if let data = try? JSONEncoder().encode(memos) { UserDefaults.standard.set(data, forKey: memosKey) }
    }

    private func loadMemos() {
        guard let data = UserDefaults.standard.data(forKey: memosKey),
              let saved = try? JSONDecoder().decode([VoiceMemo].self, from: data) else { return }
        memos = saved
    }

    @ViewBuilder
    private func categoryOption(title: String) -> some View {
        Button { draftCategory = title } label: {
            HStack(spacing: 6) {
                Image(systemName: categoryIcon(for: title))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(title.capitalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(draftCategory == title ? categoryColor(for: title) : darkSurface))
            .overlay(Capsule().stroke(draftCategory == title ? categoryColor(for: title) : Color.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func detectedCategory(for text: String) -> String {
        let lower = text.lowercased()

        if lower.contains("remind me")
            || lower.contains("remember to")
            || lower.contains("don't forget")
            || lower.contains("tomorrow")
            || lower.contains("next week")
            || lower.contains("next month")
            || lower.contains("tonight")
            || lower.contains("this evening")
            || lower.contains("call")
            || lower.contains("pm")
            || lower.contains("am")
            || lower.contains("at ")
        {
            return "reminder"
        } else if lower.contains("buy")
            || lower.contains("pick up")
            || lower.contains("bring")
            || lower.contains("grab")
            || lower.contains("get ")
            || lower.contains("write")
            || lower.contains("complete")
            || lower.contains("finish")
            || lower.contains("do ")
            || lower.contains("laundry")
            || lower.contains("shopping")
        {
            return "todo"
        } else if lower.contains("idea")
            || lower.contains("build")
            || lower.contains("what if")
            || lower.contains("concept")
            || lower.contains("brainstorm")
        {
            return "idea"
        } else {
            return "note"
        }
    }

    private func instructionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(brandYellow).frame(width: 24, alignment: .center).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 14, weight: .medium)).foregroundStyle(secondaryText).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func categoryChip(title: String, color: Color, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().fill(color))
    }
}

#Preview {
    ContentView()
        .environmentObject(PhoneConnectivityManager())
}
