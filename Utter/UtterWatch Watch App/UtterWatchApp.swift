//
//  UtterWatchApp.swift
//  UtterWatch Watch App
//
//  Created by Ritika Joshi on 3/14/26.
//

import SwiftUI
import WatchConnectivity
import Combine

@main
struct UtterWatch_Watch_AppApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var statusText = "Activating WatchConnectivity..."
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            
            DispatchQueue.main.async {
                self.statusText = "Watch session activate() called"
            }
        } else {
            DispatchQueue.main.async {
                self.statusText = "WCSession not supported on watch"
            }
        }
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.statusText = "Watch WCSession failed: \(error.localizedDescription)"
            } else {
                self.statusText = "Watch WCSession activated"
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            if session.isReachable {
                self.statusText = "iPhone reachable"
            } else {
                self.statusText = "iPhone not reachable"
            }
        }
    }
    
    func sendStartRecordingMessage() {
        do {
            try WCSession.default.updateApplicationContext(["action": "startRecording"])
            DispatchQueue.main.async {
                self.statusText = "Sent startRecording"
            }
        } catch {
            DispatchQueue.main.async {
                self.statusText = "Context send failed"
            }
        }
    }
    
    func sendStopRecordingMessage() {
            do {
                try WCSession.default.updateApplicationContext(["action": "stopRecording"])
                DispatchQueue.main.async {
                    self.statusText = "Sent stopRecording"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusText = "Stop send failed"
                }
            }
        }
    func sendAudioFile(_ url: URL) {
        guard WCSession.default.isReachable else {
            DispatchQueue.main.async {
                self.statusText = "iPhone not reachable"
            }
            return
        }

        WCSession.default.transferFile(url, metadata: ["type": "audio"])

        DispatchQueue.main.async {
            self.statusText = "Audio sent"
        }
    }
    
    
}
