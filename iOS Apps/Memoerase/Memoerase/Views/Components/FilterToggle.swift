//
//  FilterToggle.swift
//  Memoerase - Fixed Async Calls
//

import SwiftUI

struct FilterToggle: View {
    @ObservedObject var photoStore: PhotoStore
    @State private var isPressed = false
    @State private var iconScale = 1.0
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            withAnimation(AppStyles.Animations.bouncy) {
                iconScale = 1.3
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            photoStore.changeFilterMode()
            
            // Reset icon scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(AppStyles.Animations.spring) {
                    iconScale = 1.0
                }
            }
            
            // Show tooltip briefly
            withAnimation {
                showTooltip = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showTooltip = false
                }
            }
        }) {
            HStack(spacing: 12) {
                // Filter icon
                Image(systemName: photoStore.filterMode.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppStyles.Colors.primary)
                    .scaleEffect(iconScale)
                    .animation(AppStyles.Animations.bouncy, value: iconScale)
                
                // Filter mode text
                VStack(alignment: .leading, spacing: 2) {
                    Text(photoStore.filterMode.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppStyles.Colors.text)
                    
                    Text(photoStore.filterMode.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppStyles.Colors.secondaryText)
                }
                
                Spacer()
                
                // Change indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppStyles.Colors.primary.opacity(0.6))
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
                    .animation(AppStyles.Animations.spring, value: isPressed)
            }
            .padding(.horizontal, AppStyles.Dimensions.standardPadding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppStyles.Dimensions.cornerRadius)
                    .fill(AppStyles.Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyles.Dimensions.cornerRadius)
                            .stroke(
                                AppStyles.Colors.primary.opacity(isPressed ? 0.6 : 0.3),
                                lineWidth: isPressed ? 2 : 1
                            )
                    )
                    .shadow(
                        color: AppStyles.Colors.primary.opacity(isPressed ? 0.2 : 0.1),
                        radius: isPressed ? 8 : 4,
                        x: 0,
                        y: isPressed ? 4 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppStyles.Animations.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(AppStyles.Animations.quick) {
                isPressed = isPressing
            }
        } perform: {}
        .overlay(
            // Tooltip overlay
            Group {
                if showTooltip {
                    TooltipView(message: "Filter changed to \(photoStore.filterMode.rawValue)")
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
}

// MARK: - Tooltip Component
struct TooltipView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .offset(y: -50)
            .zIndex(1)
    }
}

// MARK: - Filter Mode Grid (Alternative compact view) - FIXED
struct FilterModeGrid: View {
    @ObservedObject var photoStore: PhotoStore
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                FilterModeButton(
                    mode: mode,
                    isSelected: photoStore.filterMode == mode,
                    action: {
                        if photoStore.filterMode != mode {
                            withAnimation(AppStyles.Animations.spring) {
                                photoStore.filterMode = mode
                                
                                
                                Task { @MainActor in
                                    await photoStore.batchManager.applyFilter(mode)
                                    await photoStore.loadNextPhoto()
                                }
                            }
                        }
                    }
                )
            }
        }
        .padding(.horizontal, AppStyles.Dimensions.standardPadding)
    }
}

struct FilterModeButton: View {
    let mode: FilterMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppStyles.Colors.primary)
                
                Text(mode.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : AppStyles.Colors.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppStyles.Colors.primary : AppStyles.Colors.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterToggle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FilterToggle(photoStore: PhotoStore.shared)
            FilterModeGrid(photoStore: PhotoStore.shared)
        }
        .padding()
        .background(AppStyles.Colors.secondaryBackground)
    }
}
