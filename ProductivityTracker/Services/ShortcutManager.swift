//
//  ShortcutManager.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import KeyboardShortcuts

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
            } else {
                trackingManager.startInterruption()
            }
        } else {
            // If not tracking, start a new session
            trackingManager.startSession()
        }
    }
}

// MARK: - Keyboard Shortcuts Extension

extension KeyboardShortcuts.Name {
    /// Toggle work session shortcut (default: ⌥⌃Space)
    static let toggleSession = Self("toggleSession", default: .init(.space, modifiers: [.option, .control]))
}
