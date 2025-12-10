//
//  ShortcutManager.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import KeyboardShortcuts
import UserNotifications

/// Manages global keyboard shortcuts for the app
class ShortcutManager {
    private let trackingManager: TrackingManager
    
    init(trackingManager: TrackingManager) {
        self.trackingManager = trackingManager
        setupShortcuts()
    }
    
    private func setupShortcuts() {
        // Register the toggle session shortcut
        KeyboardShortcuts.onKeyUp(for: .toggleSession) { [weak self] in
            self?.handleToggleSession()
        }
    }
    
    private func handleToggleSession() {
        if trackingManager.isTracking {
            // If tracking, toggle interruption state
            if trackingManager.isInterrupted {
                trackingManager.endInterruption()
                sendNotification(title: "Focus Resumed", body: "Interruption ended. Back to work!")
            } else {
                trackingManager.startInterruption()
                sendNotification(title: "Interruption Started", body: "Timer paused. Handle your interruption.")
            }
        } else {
            // If not tracking, start a new session
            trackingManager.startSession()
            sendNotification(title: "Session Started", body: "Focus timer started.")
        }
    }
    
    private func sendNotification(title: String, body: String) {
        if Bundle.main.bundleIdentifier != nil {
            // Use UNUserNotificationCenter if running as a bundled app
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error)")
                }
            }
        } else {
            // Fallback to osascript for standalone executable
            let script = "display notification \"\(body)\" with title \"\(title)\""
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            try? process.run()
        }
    }
}

// MARK: - Keyboard Shortcuts Extension

extension KeyboardShortcuts.Name {
    /// Toggle work session shortcut (default: ⌥⌃Space)
    static let toggleSession = Self("toggleSession", default: .init(.space, modifiers: [.option, .control]))
}
