# Utter

A voice capture app for Apple Watch and iPhone. Record quick thoughts on your wrist, then transcribe and organize them on your phone.

---

## What it does

Utter is built around a simple idea: the fastest way to capture a thought is to say it out loud. You hold a button on your Apple Watch, speak, and release. That recording gets sent to your iPhone where it's transcribed and automatically sorted into one of four categories — Todo, Reminder, Idea, or Note — based on what you said.

---

## How it works

1. **Record on Apple Watch** — Hold the screen to record, release to stop. You can review the audio before sending.
2. **Transcribe on iPhone** — Import the latest watch recording and convert it to text using on-device speech recognition.
3. **Review and save** — Check the transcript, confirm or change the category, then save it to your inbox.
4. **Inbox** — Browse your notes grouped by category. Tap a category to open it, check items off as done, or delete them.

---

## Features

- Hold-to-record on Apple Watch with live audio waveform
- On-device transcription via Apple's Speech framework
- Auto-categorization based on keywords in the transcript
- Review sheet to edit the category before saving
- Inbox grouped by category (Todo, Reminder, Idea, Note) with check-off and delete
- Watch → iPhone file transfer via WatchConnectivity
- Dark UI with yellow accents throughout

---

## Categories

| Category | Color | Used for |
|----------|-------|----------|
| Todo | Green | Tasks and actions |
| Reminder | Orange | Time-based follow-ups |
| Idea | Purple | Concepts and brainstorms |
| Note | Blue | Everything else worth keeping |

---

## Tech stack

- SwiftUI (iOS + watchOS)
- WatchConnectivity for Watch → iPhone audio transfer
- AVFoundation for audio recording and playback
- Speech framework for on-device transcription
- UserDefaults for local memo persistence

---

## Requirements

- iOS 17+
- watchOS 10+
- Xcode 15+
- An Apple Watch paired to an iPhone

---

## Project structure

```
Utter/
├── Utter/                  # iPhone app
│   ├── ContentView.swift   # Main UI — recording screen, inbox, review sheet
│   ├── VoiceMemo.swift     # Data model
│   ├── SpeechManager.swift # Recording and transcription
│   └── PhoneConnectivityManager.swift
│
└── UtterWatch Watch App/   # Watch app
    ├── ContentView.swift   # Watch UI — idle, recording, review, confirmed
    └── WatchAudioRecorder.swift
```

---

## Setup

1. Clone the repo
2. Open `Utter.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities for both the iPhone and Watch targets
4. Build and run on a real device — microphone and WatchConnectivity require physical hardware

---

Built by Ritika Joshi
