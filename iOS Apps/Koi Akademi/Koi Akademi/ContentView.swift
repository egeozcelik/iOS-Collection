//
//  ContentView.swift
//  Koi Akademi
//
//  Created by Ege on 8.08.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    WelcomeBanner()
                    
                    VStack(spacing: 20) {
                        SpecialMeditationCard()
                        
                        MeditationModules()
                        
                        SpecialMeditationCard()
                        
                        YogaModules()
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Anasayfa")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct WelcomeBanner: View {
    @State private var currentMessageIndex = 0
    @State private var shadowRadius: CGFloat = 8
    @State private var shadowOpacity: Double = 0.2
    @State private var shadowY: CGFloat = 4
    
    private let welcomeMessages = [
        "Bugün Nasılsın?",
        "Senin için seçtiklerimiz",
        "Huzurlu bir gün dileriz",
        "Nefes almayı unutma",
        "İçsel yolculuğuna hoş geldin",
        "Bugün kendine zaman ayır"
    ]
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.25, blue: 0.45),
                            Color(red: 0.25, green: 0.35, blue: 0.55),
                            Color(red: 0.2, green: 0.4, blue: 0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(shadowOpacity),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(welcomeMessages[currentMessageIndex])
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 1, y: 2)
                    
                    Text("Koi Akademi ile iç huzurunu keşfet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                Image(systemName: "leaf.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .onAppear {
            startShadowAnimation()
            selectRandomMessage()
        }
    }
    
    private func startShadowAnimation() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            shadowRadius = 20
            shadowOpacity = 0.7
            shadowY = 12
        }
    }
    
    private func selectRandomMessage() {
        currentMessageIndex = Int.random(in: 0..<welcomeMessages.count)
    }
}

struct SpecialMeditationCard: View {
    var body: some View {
        Text("SpecialMeditationCard - Yakında...")
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}

struct MeditationModules: View {
    var body: some View {
        Text("MeditationModules - Yakında...")
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}

struct YogaModules: View {
    var body: some View {
        Text("YogaModules - Yakında...")
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}


#Preview {
    ContentView()
}
