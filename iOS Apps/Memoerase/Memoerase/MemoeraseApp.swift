//
//  MemoeraseApp.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

// MemoEraseApp.swift
import SwiftUI

// MemoEraseApp.swift
import SwiftUI

@main
struct MemoeraseApp: App {
    @State private var isSplashActive = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    // Main app content (şimdilik basit placeholder)
                    ContentView()
                        .transition(.opacity)
                } else {
                    // Splash screen
                    SplashScreen(isActive: $isSplashActive)
                        .transition(.opacity)
                }
            }
            .animation(AppStyles.Animations.smooth, value: isSplashActive)
        }
    }
}

