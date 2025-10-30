//
//  ContentView.swift
//  Memoerase - Updated with Batch Loading
//
import SwiftUI

struct ContentView: View {
    @StateObject private var photoStore = PhotoStore.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                if photoStore.hasPermission {
                    if photoStore.isInitialLoading {
                        InitialLoadingView(photoStore: photoStore)
                    } else if photoStore.hasPhotos {
                        MainContentView()
                            .environmentObject(photoStore)
                            .background(AppStyles.Colors.background)
                    } else {
                        EmptyLibraryView()
                    }
                } else {
                    PermissionView(photoStore: photoStore)
                }
            }
        }
        .errorToast(photoStore: photoStore)
        .onAppear {
            photoStore.checkPermissionAndLoadPhotos()
            
            if photoStore.appStats.sessionsCount == 0 ||
               photoStore.appStats.lastSessionDate?.timeIntervalSinceNow ?? 0 < -3600 {
                photoStore.startNewSession()
            }
        }
    }
}

struct MainContentView: View {
    @EnvironmentObject var photoStore: PhotoStore
    
    var body: some View {
        VStack(spacing: 0) {
            StatsHeader(photoStore: photoStore)
                .padding(.horizontal)
                
            PhotoSwipeView()
                .environmentObject(photoStore)
        }
    }
}

// MARK: - Updated Loading View with Progress
struct InitialLoadingView: View {
    @ObservedObject var photoStore: PhotoStore
    @State private var animationRotation = 0.0
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated logo
            ZStack {
                Circle()
                    .stroke(AppStyles.Colors.primary.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppStyles.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animationRotation))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            animationRotation = 360
                        }
                    }
                
                Image(systemName: "photo.stack")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(AppStyles.Colors.primary)
            }
            
            VStack(spacing: 16) {
                Text("Loading Your Photos")
                    .font(AppStyles.Typography.title)
                    .foregroundColor(AppStyles.Colors.primary)
                
                Text("Analyzing \(photoStore.batchManager.totalPhotoCount) photos...")
                    .font(AppStyles.Typography.body)
                    .foregroundColor(AppStyles.Colors.secondaryText)
                
                // Progress bar
                if photoStore.batchManager.totalPhotoCount > 0 {
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppStyles.Colors.secondaryBackground)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppStyles.Colors.primaryGradient)
                                .frame(width: UIScreen.main.bounds.width * 0.6 * photoStore.batchManager.loadingProgress, height: 8)
                                .animation(AppStyles.Animations.smooth, value: photoStore.batchManager.loadingProgress)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.6)
                        
                        Text("\(Int(photoStore.batchManager.loadingProgress * 100))% ready")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppStyles.Colors.secondaryText)
                    }
                }
                
                Text("This will only take a few seconds...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Supporting Views (unchanged)
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📱")
                .font(.system(size: 80))
            
            Text("No Photos Found")
                .font(AppStyles.Typography.title)
                .foregroundColor(AppStyles.Colors.text)
            
            Text("Your photo library appears to be empty.")
                .font(AppStyles.Typography.body)
                .foregroundColor(AppStyles.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct PermissionView: View {
    let photoStore: PhotoStore
    
    var body: some View {
        VStack(spacing: 30) {
            Text("📸")
                .font(.system(size: 80))
            
            Text("Photo Access Needed")
                .font(AppStyles.Typography.title)
                .foregroundColor(AppStyles.Colors.text)
            
            Text("Memoerase needs access to your photo library to help you organize and delete unwanted photos.")
                .font(AppStyles.Typography.body)
                .foregroundColor(AppStyles.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Grant Access") {
                photoStore.requestPermission()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
    }
}
