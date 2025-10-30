//
//  SplashView.swift
//  Koi Akademi
//
//  Created by Ege on 8.08.2025.
//
import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainContent = false
    
    var body: some View {
        if showMainContent {
            ContentView()
        } else {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.2, blue: 0.4),
                            Color(red: 0.2, green: 0.4, blue: 0.6),
                            Color(red: 0.1, green: 0.3, blue: 0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .opacity(isAnimating ? 0.8 : 1.0)
                            
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        }
                        
                        VStack(spacing: 8) {
                            Text("KOI")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .offset(y: isAnimating ? 0 : 50)
                                .opacity(isAnimating ? 1 : 0)
                            
                            Text("AKADEMİ")
                                .font(.system(size: 32, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .offset(y: isAnimating ? 0 : 50)
                                .opacity(isAnimating ? 1 : 0)
                        }
                        
                        Text("Meditasyon & Yoga")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                            .offset(y: isAnimating ? 0 : 30)
                            .opacity(isAnimating ? 1 : 0)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showMainContent = true
                    }
                }
            }
        }
    }
}

