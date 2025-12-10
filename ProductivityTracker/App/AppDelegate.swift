//
//  AppDelegate.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Cocoa
import SwiftUI
import SwiftData
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var dashboardWindow: NSWindow?
    
    // Services
    var trackingManager: TrackingManager?
    var shortcutManager: ShortcutManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Notification Permissions only if we have a bundle identifier (running as App)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Error requesting notification authorization: \(error)")
                }
            }
        }
        
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Productivity Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 400)
        popover.behavior = .transient
        self.popover = popover
        
        // Get the model context from the app
        let container = ProductivityTrackerApp.sharedModelContainer
        let modelContext = ModelContext(container)
        
        // Initialize services
        trackingManager = TrackingManager(modelContext: modelContext)
        
        // Setup tracking state callback
        trackingManager?.onTrackingStateChanged = { [weak self] isTracking in
            DispatchQueue.main.async {
                self?.updateMenuBarIcon(isTracking: isTracking)
            }
        }
        
        // Set initial state
        updateMenuBarIcon(isTracking: trackingManager!.isTracking)
        
        shortcutManager = ShortcutManager(trackingManager: trackingManager!)
        
        // Set popover content view with dependencies
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(trackingManager: trackingManager!)
                .modelContainer(container)
        )
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func showDashboard() {
        if dashboardWindow == nil {
            // Create the dashboard window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.center()
            window.title = "Productivity Dashboard"
            window.isReleasedWhenClosed = false
            
            let container = ProductivityTrackerApp.sharedModelContainer
            window.contentView = NSHostingView(
                rootView: DashboardView(trackingManager: trackingManager!)
                    .modelContainer(container)
            )
            
            dashboardWindow = window
        }
        
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func updateMenuBarIcon(isTracking: Bool) {
        guard let button = statusItem?.button else { return }
        let imageName = isTracking ? "play.circle" : "clock"
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Productivity Tracker")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showDashboard()
        }
        return true
    }
}
