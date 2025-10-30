//
//  SettingsView.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var photoStore: PhotoStore
    @State private var showingResetAlert = false
    @State private var showingInfoSheet = false
    @State private var deviceStorageInfo = StorageManager.shared.getStorageInfoForDisplay()
    
    var body: some View {
        NavigationView {
            List {
                // App Info Section
                Section {
                    AppInfoCard()
                } header: {
                    Text("App Information")
                        .font(AppStyles.Typography.caption)
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                // Statistics Section
                Section {
                    StatisticsSection(photoStore: photoStore)
                } header: {
                    Text("Your Statistics")
                        .font(AppStyles.Typography.caption)
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                // Device Storage Section
                Section {
                    DeviceStorageSection(storageInfo: deviceStorageInfo)
                } header: {
                    Text("Device Storage")
                        .font(AppStyles.Typography.caption)
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                // Actions Section
                Section {
                    ActionsSection(
                        photoStore: photoStore,
                        showingResetAlert: $showingResetAlert,
                        showingInfoSheet: $showingInfoSheet
                    )
                } header: {
                    Text("Actions")
                        .font(AppStyles.Typography.caption)
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                // App Version Footer
                Section {
                    AppVersionFooter()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppStyles.Colors.primary)
                }
            }
        }
        .alert("Reset Statistics", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                resetStatistics()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your cleaning statistics. This action cannot be undone.")
        }
        .sheet(isPresented: $showingInfoSheet) {
            AppInfoSheet()
        }
        .onAppear {
            refreshStorageInfo()
        }
    }
    
    private func resetStatistics() {
        AppStats.reset()
        photoStore.appStats = AppStats()
        
        // Success haptic
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    private func refreshStorageInfo() {
        deviceStorageInfo = StorageManager.shared.getStorageInfoForDisplay()
    }
}

// MARK: - App Info Card
struct AppInfoCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppStyles.Colors.primaryGradient)
                    .frame(width: 60, height: 60)
                
                Text("ME")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Memoerase")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppStyles.Colors.text)
                
                Text("Clean Your Memories, Save Your Space")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
                
                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Statistics Section
struct StatisticsSection: View {
    @ObservedObject var photoStore: PhotoStore
    
    var body: some View {
        VStack(spacing: 12) {
            StatRow(
                title: "Photos Deleted",
                value: "\(photoStore.appStats.totalDeletedCount)",
                icon: "trash.fill",
                color: AppStyles.Colors.deleteRed
            )
            
            StatRow(
                title: "Space Cleaned",
                value: photoStore.appStats.formattedDeletedSize,
                icon: "externaldrive.fill",
                color: AppStyles.Colors.keepGreen
            )
            
            StatRow(
                title: "Cleaning Sessions",
                value: "\(photoStore.appStats.sessionsCount)",
                icon: "clock.fill",
                color: AppStyles.Colors.primary
            )
            
            if photoStore.appStats.sessionsCount > 0 {
                StatRow(
                    title: "Average per Session",
                    value: photoStore.appStats.averageDeletionPerSession,
                    icon: "chart.bar.fill",
                    color: AppStyles.Colors.secondary
                )
            }
            
            if let lastSession = photoStore.appStats.lastSessionDate {
                StatRow(
                    title: "Last Session",
                    value: lastSession.timeAgo(),
                    icon: "calendar",
                    color: AppStyles.Colors.secondaryText
                )
            }
        }
    }
}

// MARK: - Device Storage Section
struct DeviceStorageSection: View {
    let storageInfo: (free: String, total: String, freePercentage: Double)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Free Space")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.text)
                
                Spacer()
                
                Text(storageInfo.free)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(storageInfo.freePercentage > 20 ? AppStyles.Colors.keepGreen : AppStyles.Colors.deleteRed)
            }
            
            // Storage bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppStyles.Colors.secondaryBackground)
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                storageInfo.freePercentage > 20 ? AppStyles.Colors.keepGreen : AppStyles.Colors.deleteRed,
                                storageInfo.freePercentage > 20 ? AppStyles.Colors.primary : AppStyles.Colors.deleteRed.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.7 * (storageInfo.freePercentage / 100), height: 12)
            }
            
            HStack {
                Text("Total: \(storageInfo.total)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
                
                Spacer()
                
                Text("\(Int(storageInfo.freePercentage))% free")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Actions Section
struct ActionsSection: View {
    @ObservedObject var photoStore: PhotoStore
    @Binding var showingResetAlert: Bool
    @Binding var showingInfoSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ActionRow(
                title: "Refresh Library",
                subtitle: "Update photo count and sizes",
                icon: "arrow.clockwise",
                color: AppStyles.Colors.primary
            ) {
                photoStore.loadPhotos()
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            
            Divider()
                .padding(.leading, 50)
            
            ActionRow(
                title: "App Information",
                subtitle: "About Memoerase",
                icon: "info.circle",
                color: AppStyles.Colors.secondary
            ) {
                showingInfoSheet = true
            }
            
            Divider()
                .padding(.leading, 50)
            
            ActionRow(
                title: "Reset Statistics",
                subtitle: "Clear all cleaning data",
                icon: "trash",
                color: AppStyles.Colors.deleteRed
            ) {
                showingResetAlert = true
            }
        }
    }
}

// MARK: - Supporting Components
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.text)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

struct ActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppStyles.Colors.text)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppStyles.Colors.secondaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AppVersionFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Made with ❤️ for better photo organization")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Text("Memoerase v1.0.0")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - App Info Sheet
struct AppInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App logo and name
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppStyles.Colors.primaryGradient)
                                .frame(width: 100, height: 100)
                            
                            Text("ME")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("Memoerase")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppStyles.Colors.text)
                        
                        Text("Clean Your Memories, Save Your Space")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppStyles.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppStyles.Colors.text)
                        
                        FeatureRow(
                            icon: "photo.stack",
                            title: "Smart Photo Organization",
                            description: "Random, chronological, and custom sorting options"
                        )
                        
                        FeatureRow(
                            icon: "hand.draw",
                            title: "Intuitive Swipe Controls",
                            description: "Tinder-style interface for quick photo decisions"
                        )
                        
                        FeatureRow(
                            icon: "chart.pie",
                            title: "Storage Analytics",
                            description: "Track your cleaning progress and space saved"
                        )
                        
                        FeatureRow(
                            icon: "shield.checkered",
                            title: "Safe & Secure",
                            description: "All operations happen locally on your device"
                        )
                    }
                    
                    // Version info
                    VStack(spacing: 8) {
                        Text("Version 1.0.0")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppStyles.Colors.primary)
                        
                        Text("Built with SwiftUI")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppStyles.Colors.secondaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppStyles.Colors.primary)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppStyles.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppStyles.Colors.text)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(photoStore: PhotoStore.shared)
    }
}
