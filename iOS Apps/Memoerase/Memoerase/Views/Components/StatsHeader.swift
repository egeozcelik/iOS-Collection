// StatsHeader.swift - Updated for StorageManager
import SwiftUI

struct StatsHeader: View {
    @ObservedObject var photoStore: PhotoStore
    @StateObject private var storageManager = StorageManager.shared
    @State private var animateNumbers = false
    @State private var showDetails = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatItem(
                    title: "Total Library",
                    value: storageManager.formattedCurrentSize,
                    subtitle: "\(photoStore.photosRemaining) photos",
                    color: AppStyles.Colors.primary,
                    icon: "photo.stack",
                    isLoading: storageManager.isLoadingStorage
                )
                
                Spacer()
                
                StatItem(
                    title: "Session Clean",
                    value: storageManager.formattedSessionDeleted,
                    subtitle: "\(photoStore.appStats.totalDeletedCount) deleted",
                    color: AppStyles.Colors.keepGreen,
                    icon: "trash.fill"
                )
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppStyles.Colors.primary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(AppStyles.Colors.primary.opacity(0.1))
                        )
                }
            }
            
            // Progress bar - sadece session deletion varsa göster
            if storageManager.sessionDeleted > 0 {
                ProgressBar(
                    current: storageManager.sessionDeleted,
                    total: storageManager.totalLibrarySize,
                    label: "Session Progress"
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            // Lifetime stats - sadece lifetime deletion varsa göster
            if storageManager.lifetimeDeletedSize > 0 {
                LifetimeStatsRow(storageManager: storageManager)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if showDetails {
                VStack(spacing: 8) {
                    Divider()
                        .background(AppStyles.Colors.primary.opacity(0.3))
                    
                    FilterToggle(photoStore: photoStore)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Error handling
            if let error = storageManager.storageError {
                ErrorBanner(message: error) {
                    storageManager.refreshStorageInfo()
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            CardContainer(backgroundColor: AppStyles.Colors.secondaryBackground) {
                EmptyView()
            }
        )
        .onTapGesture {
            withAnimation(AppStyles.Animations.spring) {
                showDetails.toggle()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(photoStore: photoStore)
        }
        .onAppear {
            // Storage bilgilerini yükle
            Task {
                await storageManager.loadTotalLibrarySize()
            }
            
            withAnimation(AppStyles.Animations.smooth.delay(0.5)) {
                animateNumbers = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // App foreground'a geldiğinde storage'ı refresh et
            storageManager.refreshStorageInfo()
        }
    }
}

// MARK: - Updated Stat Item Component
struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    var isLoading: Bool = false
    
    @State private var numberScale = 0.8
    @State private var iconRotation = -15.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title and icon
            HStack(spacing: 6) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(color)
                            .rotationEffect(.degrees(iconRotation))
                            .animation(AppStyles.Animations.bouncy.delay(0.3), value: iconRotation)
                    }
                }
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
            }
            
            // Main value
            Text(isLoading ? "Loading..." : value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .scaleEffect(numberScale)
                .animation(AppStyles.Animations.bouncy.delay(0.2), value: numberScale)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.secondaryText)
        }
        .onAppear {
            withAnimation {
                numberScale = 1.0
                iconRotation = 0
            }
        }
    }
}

// MARK: - Lifetime Stats Row
struct LifetimeStatsRow: View {
    @ObservedObject var storageManager: StorageManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("LIFETIME CLEANED")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
                
                Text(storageManager.formattedLifetimeDeleted)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondary)
            }
            
            Spacer()
            
            Button("Reset") {
                withAnimation {
                    storageManager.resetStats()
                }
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(AppStyles.Colors.deleteRed.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppStyles.Colors.secondary.opacity(0.1))
        )
    }
}

// MARK: - Progress Bar Component (Updated)
struct ProgressBar: View {
    let current: Int64
    let total: Int64
    let label: String
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
                
                Spacer()
                
                Text("\(String(format: "%.1f", progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppStyles.Colors.keepGreen)
            }
            
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppStyles.Colors.secondaryBackground)
                    .frame(height: 6)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppStyles.Colors.keepGreen,
                                AppStyles.Colors.primary
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.7 * animatedProgress, height: 6)
                    .animation(AppStyles.Animations.smooth.delay(0.5), value: animatedProgress)
            }
        }
        .onAppear {
            withAnimation {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppStyles.Colors.deleteRed)
            
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.text)
                .lineLimit(2)
            
            Spacer()
            
            Button("Retry") {
                onRetry()
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(AppStyles.Colors.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppStyles.Colors.deleteRed.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppStyles.Colors.deleteRed.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatsHeader_Previews: PreviewProvider {
    static var previews: some View {
        StatsHeader(photoStore: PhotoStore.shared)
            .padding()
            .background(AppStyles.Colors.secondaryBackground)
    }
}
