//
//  FreeFlowSystemWatchOSApp.swift
//  FreeFlowSystemWatchOS Watch App
//
//  Created by Ege on 14.05.2025.
//

import SwiftUI

@main
struct FreeFlowSystemWatchOS_Watch_AppApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
        }
    }
}
