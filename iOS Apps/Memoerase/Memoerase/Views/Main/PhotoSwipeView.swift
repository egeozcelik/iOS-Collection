// PhotoSwipeView.swift - Fixed for Batch Loading
import SwiftUI

struct PhotoSwipeView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var cardKey = UUID()
    @State private var showInstructions = true
    @State private var deletionSuccess = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ZStack {
                        if let currentPhoto = photoStore.currentPhoto {
                            PhotoCard(
                                photo: currentPhoto,
                                onSwipeLeft: {
                                    handlePhotoDelete()
                                },
                                onSwipeRight: {
                                    handlePhotoSkip()
                                }
                            )
                            .id(cardKey)
                        } else if !photoStore.isLoadingNextPhoto {  // FIX: isLoading -> isLoadingNextPhoto
                            EmptyPhotoState()
                        }
                        
                        if isDeleting {
                            DeletionOverlay()
                        }
                        
                        if deletionSuccess {
                            SuccessFeedback()
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Loading next photo indicator
                        if photoStore.isLoadingNextPhoto {
                            NextPhotoLoadingView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Instructions overlay - en üstte splash screen gibi
                if showInstructions {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    InstructionsOverlay {
                        withAnimation(AppStyles.Animations.smooth) {
                            showInstructions = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .animation(AppStyles.Animations.spring, value: photoStore.currentPhoto?.id)
        .animation(AppStyles.Animations.smooth, value: showInstructions)
        .onAppear {
            // Auto hide instructions after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }
    
    private func handlePhotoDelete() {
        guard !isDeleting else { return }
        
        withAnimation(AppStyles.Animations.quick) {
            isDeleting = true
        }
        
        photoStore.deleteCurrentPhoto { success in
            DispatchQueue.main.async {
                if success {
                    // Show success feedback
                    self.showSuccessFeedback()
                    
                    // Update card key to force recreation
                    withAnimation(AppStyles.Animations.spring) {
                        self.cardKey = UUID()
                    }
                } else {
                    // Show error (for now just continue)
                    print("❌ Deletion failed")
                }
                
                withAnimation(AppStyles.Animations.smooth) {
                    self.isDeleting = false
                }
            }
        }
    }
    
    private func handlePhotoSkip() {
        // Skip current photo and load next - FIX: async call handling
        Task { @MainActor in
            photoStore.skipCurrentPhoto()
            
            // Update card key to force recreation
            withAnimation(AppStyles.Animations.spring) {
                cardKey = UUID()
            }
        }
        
        // Light haptic feedback for skip
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func showSuccessFeedback() {
        withAnimation(AppStyles.Animations.bouncy) {
            deletionSuccess = true
        }
        
        // Success haptic
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // Hide after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AppStyles.Animations.smooth) {
                deletionSuccess = false
            }
        }
    }
}

// MARK: - Supporting Views

// YENİ: Next Photo Loading Indicator
struct NextPhotoLoadingView: View {
    @State private var rotationAngle = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppStyles.Colors.primary.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppStyles.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            }
            
            Text("Loading next photo...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppStyles.Colors.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyles.Colors.background.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct InstructionsOverlay: View {
    let onDismiss: () -> Void
    @State private var instructionScale = 1.0
    @State private var overlayOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("How to use Memoerase")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Use swipe gestures to organize your photos")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Visual instruction
            HStack(spacing: 40) {
                SwipeInstructionItem(
                    icon: "arrow.left",
                    text: "Delete",
                    description: "Remove photo",
                    color: AppStyles.Colors.deleteRed
                )
                
                SwipeInstructionItem(
                    icon: "arrow.right",
                    text: "Skip",
                    description: "Keep & continue",
                    color: AppStyles.Colors.keepGreen
                )
            }
            .scaleEffect(instructionScale)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                ) {
                    instructionScale = 1.1
                }
            }
            
            Button("Got it!") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 120)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: AppStyles.Dimensions.cornerRadius)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyles.Dimensions.cornerRadius)
                        .stroke(AppStyles.Colors.primary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
        )
        .padding(.horizontal, 30)
        .opacity(overlayOpacity)
        .onAppear {
            withAnimation(AppStyles.Animations.smooth.delay(0.1)) {
                overlayOpacity = 1.0
            }
        }
    }
}

struct SwipeInstructionItem: View {
    let icon: String
    let text: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(text)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct BackgroundPattern: View {
    var body: some View {
        ZStack {
            // Subtle grid pattern
            Path { path in
                let spacing: CGFloat = 50
                let width = UIScreen.main.bounds.width
                let height = UIScreen.main.bounds.height
                
                // Vertical lines
                for x in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(AppStyles.Colors.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

struct EmptyPhotoState: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 80))
            
            Text("All Done!")
                .font(AppStyles.Typography.title)
                .foregroundColor(AppStyles.Colors.primary)
            
            Text("You've reviewed all your photos. Great job cleaning up your library!")
                .font(AppStyles.Typography.body)
                .foregroundColor(AppStyles.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct DeletionOverlay: View {
    @State private var overlayOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Deleting photo...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
        .opacity(overlayOpacity)
        .onAppear {
            withAnimation(AppStyles.Animations.smooth) {
                overlayOpacity = 1.0
            }
        }
    }
}

struct SuccessFeedback: View {
    @State private var checkmarkScale = 0.5
    @State private var checkmarkOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppStyles.Colors.keepGreen)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(checkmarkScale)
            .opacity(checkmarkOpacity)
            
            Text("Photo Deleted!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppStyles.Colors.keepGreen)
        }
        .onAppear {
            withAnimation(AppStyles.Animations.bouncy) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }
}

struct PhotoSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoSwipeView()
            .environmentObject(PhotoStore.shared)
    }
}
