//
//  UtterApp.swift
//  Utter
//
//  Created by Ritika Joshi on 3/14/26.
//

import SwiftUI
import WatchConnectivity
import Combine

@main
struct UtterApp: App {
    @StateObject private var connectivityManager = PhoneConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

final class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var statusText = "Activating WatchConnectivity..."

    override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            statusText = "WCSession failed: \(error.localizedDescription)"
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            statusText = "WCSession activated on iPhone"
            print("WCSession activated on iPhone with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) { }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        DispatchQueue.main.async {
            print("Message from watch:", message)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        DispatchQueue.main.async {
            let action = applicationContext["action"] as? String ?? "unknown"
            self.statusText = "Received from watch: \(action)"
            print("ApplicationContext from watch:", applicationContext)
        }
    }

    func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        let filename = file.fileURL.lastPathComponent

        // Save to Documents/utter-recordings/
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("utter-recordings", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appendingPathComponent(filename)

            // Remove existing file at destination if present
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.copyItem(at: file.fileURL, to: destination)

            DispatchQueue.main.async {
                self.statusText = "Saved: \(filename)"
                print("Saved watch file to:", destination.path)
            }
        } catch {
            DispatchQueue.main.async {
                self.statusText = "Failed to save: \(error.localizedDescription)"
                print("Failed to save watch file:", error.localizedDescription)
            }
        }
    }
}
