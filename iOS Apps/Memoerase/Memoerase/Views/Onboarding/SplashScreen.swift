//
//  SplashScreen.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    
    @State private var logoScale = 0.5
    @State private var logoRotation = -30.0
    @State private var textOpacity = 0.0
    @State private var backgroundCircleScale = 0.0
    @State private var iconPositions = [CGSize](repeating: .zero, count: 3)
    
    var body: some View {
        ZStack {
            // Background gradient
            AppStyles.Colors.primaryGradient
                .ignoresSafeArea()
            
            // Background decorative circles
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .scaleEffect(backgroundCircleScale)
                .animation(AppStyles.Animations.smooth, value: backgroundCircleScale)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 350, height: 350)
                .scaleEffect(backgroundCircleScale * 0.8)
                .animation(AppStyles.Animations.smooth.delay(0.2), value: backgroundCircleScale)
            
            VStack(spacing: 30) {
                // App logo container
                ZStack {
                    // Main logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    // Floating icons around the logo
                    Group {
                        // Photo icon
                        Image(systemName: "photo.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(AppStyles.Colors.primary)
                            .offset(iconPositions[0])
                            .offset(x: -40, y: -40)
                        
                        // Trash icon
                        Image(systemName: "trash.fill")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(AppStyles.Colors.deleteRed)
                            .offset(iconPositions[1])
                            .offset(x: 45, y: -25)
                        
                        // Storage icon
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(AppStyles.Colors.secondary)
                            .offset(iconPositions[2])
                            .offset(x: 0, y: 50)
                    }
                    
                    // Main app letter/icon
                    VStack(spacing: 4) {
                        Text("ME")
                            .font(.system(size: 45, weight: .black, design: .rounded))
                            .foregroundColor(AppStyles.Colors.primary)
                        
                        Text("✨")
                            .font(.system(size: 20))
                    }
                }
                .scaleEffect(logoScale)
                .rotationEffect(.degrees(logoRotation))
                .animation(AppStyles.Animations.bouncy, value: logoScale)
                .animation(AppStyles.Animations.bouncy, value: logoRotation)
                
                // App name and tagline
                VStack(spacing: 8) {
                    Text("MemoErase")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Clean Your Memories, Save Your Space")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)
                .animation(AppStyles.Animations.smooth.delay(0.8), value: textOpacity)
            }
        }
        .onAppear {
            startAnimations()
            
            // Auto transition after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(AppStyles.Animations.smooth) {
                    isActive = true
                }
            }
        }
    }
    
    private func startAnimations() {
        // Background circles
        withAnimation(AppStyles.Animations.smooth.delay(0.1)) {
            backgroundCircleScale = 1.0
        }
        
        // Logo animation
        withAnimation(AppStyles.Animations.bouncy.delay(0.3)) {
            logoScale = 1.0
            logoRotation = 0
        }
        
        // Text animation
        withAnimation(AppStyles.Animations.smooth.delay(0.8)) {
            textOpacity = 1.0
        }
        
        // Floating icons animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(1.2)
        ) {
            iconPositions = [
                CGSize(width: 5, height: -5),
                CGSize(width: -3, height: 4),
                CGSize(width: 4, height: -3)
            ]
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen(isActive: .constant(false))
    }
}
