// PhotoCard.swift - Fixed Index Synchronization
import SwiftUI
import Photos

struct PhotoCard: View {
    let photo: Photo
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle = 0.0
    @State private var cardOpacity = 1.0
    
    // Swipe detection
    @State private var swipeDirection: SwipeDirection = .none
    @State private var showSwipeIndicator = false
    @State private var isProcessingSwipe = false  // YENİ: Çift işlemi önlemek için
    
    // Callbacks
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    private let swipeThreshold: CGFloat = 120
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    
    var body: some View {
        ZStack {
            // Main card container with image background
            RoundedRectangle(cornerRadius: 20)
                .fill(AppStyles.Colors.secondaryBackground)
                .frame(width: cardWidth, height: cardHeight)
                .shadow(
                    color: getShadowColor(),
                    radius: getShadowRadius(),
                    x: 0,
                    y: getShadowY()
                )
                .overlay(
                    // Background image
                    Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipped()
                                .cornerRadius(20)
                                .opacity(cardOpacity)
                        } else if isLoading {
                            LoadingPlaceholder()
                        }
                    }
                )
                .overlay(
                    // Swipe overlay
                    Group {
                        if showSwipeIndicator {
                            SwipeOverlay(direction: swipeDirection)
                        }
                    }
                )
                .overlay(
                    // Bottom info strip
                    VStack {
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(photo.formattedDate)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text(photo.timeAgo)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(photo.formattedSize)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Size")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(.white)
                                .opacity(0.95)
                        )
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    }
                )
                
                // YENİ: Photo ID debug overlay (test için)
                .overlay(
                    VStack {
                        HStack {
                            Text("ID: \(photo.id.prefix(8))")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                )
        }
        .offset(dragOffset)
        .rotationEffect(.degrees(rotationAngle))
        .scaleEffect(getCardScale())
        .animation(AppStyles.Animations.spring, value: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // YENİ: Swipe işlemi devam ediyorsa ignore et
                    guard !isProcessingSwipe else { return }
                    handleDragChanged(value)
                }
                .onEnded { value in
                    // YENİ: Swipe işlemi devam ediyorsa ignore et
                    guard !isProcessingSwipe else { return }
                    handleDragEnded(value)
                }
        )
        .onAppear {
            loadImage()
        }
    }
    
    // MARK: - Image Loading
    private func loadImage() {
        PhotoLibraryManager.shared.loadImage(
            for: photo,
            targetSize: CGSize(width: 400, height: 600)
        ) { loadedImage in
            withAnimation(AppStyles.Animations.smooth) {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Drag Handling - GÜNCELLENDİ
    private func handleDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation
        
        // Calculate rotation based on horizontal drag
        let horizontalOffset = value.translation.width
        rotationAngle = Double(horizontalOffset / 300) * 15
        
        // Determine swipe direction and show indicator
        let newDirection = getSwipeDirection(from: horizontalOffset)
        if newDirection != swipeDirection {
            swipeDirection = newDirection
            showSwipeIndicator = abs(horizontalOffset) > 50
        }
        
        // Haptic feedback at threshold
        if abs(horizontalOffset) > swipeThreshold && !showSwipeIndicator {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let dragDistance = abs(value.translation.width)
        let velocity = abs(value.velocity.width)
        
        // Determine if swipe is strong enough
        let shouldSwipe = dragDistance > swipeThreshold || velocity > 1000
        
        if shouldSwipe {
            // FIX: Önce callback'i çağır, sonra animasyon
            isProcessingSwipe = true
            performSwipeAction(direction: swipeDirection)
            performSwipeAnimation(direction: swipeDirection)
        } else {
            // Snap back to center
            withAnimation(AppStyles.Animations.spring) {
                resetCardPosition()
            }
        }
    }
    
    // YENİ: Swipe action ve animation'ı ayırdık
    private func performSwipeAction(direction: SwipeDirection) {
        print("🎯 Swipe action triggered: \(direction) for photo: \(photo.id.prefix(8))")
        
        switch direction {
        case .left:
            onSwipeLeft()   // HEMEN çağır, bekletme!
        case .right:
            onSwipeRight()  // HEMEN çağır, bekletme!
        case .none:
            break
        }
    }
    
    private func performSwipeAnimation(direction: SwipeDirection) {
        let screenWidth = UIScreen.main.bounds.width
        let finalOffset: CGSize
        let finalRotation: Double
        
        switch direction {
        case .left:
            finalOffset = CGSize(width: -screenWidth, height: dragOffset.height)
            finalRotation = -30
        case .right:
            finalOffset = CGSize(width: screenWidth, height: dragOffset.height)
            finalRotation = 30
        case .none:
            resetCardPosition()
            return
        }
        
        // Animate card out
        withAnimation(AppStyles.Animations.spring) {
            dragOffset = finalOffset
            rotationAngle = finalRotation
            cardOpacity = 0.3
        }
        
        // Reset processing flag after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isProcessingSwipe = false
        }
    }
    
    private func resetCardPosition() {
        dragOffset = .zero
        rotationAngle = 0
        cardOpacity = 1.0
        showSwipeIndicator = false
        swipeDirection = .none
        isProcessingSwipe = false
    }
    
    // MARK: - Helper Methods
    private func getSwipeDirection(from offsetX: CGFloat) -> SwipeDirection {
        if abs(offsetX) < 30 { return .none }
        return offsetX < 0 ? .left : .right
    }
    
    private func getCardScale() -> CGFloat {
        let dragFactor = abs(dragOffset.width) / 200
        return max(0.95, 1.0 - dragFactor * 0.05)
    }
    
    private func getShadowColor() -> Color {
        switch swipeDirection {
        case .left, .right:
            return AppStyles.Colors.deleteRed.opacity(0.3)
        case .none:
            return Color.black.opacity(0.15)
        }
    }
    
    private func getShadowRadius() -> CGFloat {
        abs(dragOffset.width) > 50 ? 20 : 15
    }
    
    private func getShadowY() -> CGFloat {
        abs(dragOffset.width) > 50 ? 10 : 5
    }
}

// MARK: - Supporting Views (unchanged)
struct LoadingPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppStyles.Colors.secondaryBackground)
            
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppStyles.Colors.primary))
                    .scaleEffect(1.5)
                
                Text("Loading photo...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppStyles.Colors.secondaryText)
            }
        }
    }
}

struct SwipeOverlay: View {
    let direction: SwipeDirection
    @State private var overlayScale = 0.8
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(getOverlayColor().opacity(0.7))
            
            // Action icon and text
            VStack(spacing: 8) {
                Image(systemName: getOverlayIcon())
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(overlayScale)
                
                Text(getOverlayText())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(AppStyles.Animations.bouncy.repeatForever(autoreverses: true)) {
                overlayScale = 1.2
            }
        }
    }
    
    private func getOverlayColor() -> Color {
        switch direction {
        case .left, .right:
            return AppStyles.Colors.deleteRed
        case .none:
            return .clear
        }
    }
    
    private func getOverlayIcon() -> String {
        switch direction {
        case .left, .right:
            return "trash.fill"
        case .none:
            return ""
        }
    }
    
    private func getOverlayText() -> String {
        switch direction {
        case .left, .right:
            return "DELETE"
        case .none:
            return ""
        }
    }
}

struct PhotoCard_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample photo for preview
        let sampleAsset = PHAsset()
        let samplePhoto = Photo(asset: sampleAsset)
        
        PhotoCard(
            photo: samplePhoto,
            onSwipeLeft: { print("Swiped left") },
            onSwipeRight: { print("Swiped right") }
        )
        .padding()
        .background(AppStyles.Colors.secondaryBackground)
    }
}

// MARK: - Extension for specific corner radius (unchanged)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
