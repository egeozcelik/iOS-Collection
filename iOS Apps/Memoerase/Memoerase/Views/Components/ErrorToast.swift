//
//  ErrorToast.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import SwiftUI

struct ErrorToast: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppStyles.Colors.deleteRed)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(AppStyles.Animations.spring) {
                offset = 0
                opacity = 1
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissToast()
            }
        }
        .onTapGesture {
            dismissToast()
        }
    }
    
    private func dismissToast() {
        withAnimation(AppStyles.Animations.smooth) {
            offset = -100
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Error Toast Modifier
struct ErrorToastModifier: ViewModifier {
    @ObservedObject var photoStore: PhotoStore
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let errorMessage = photoStore.lastError {
                    ErrorToast(message: errorMessage) {
                        photoStore.clearError()
                    }
                    .padding(.horizontal, 20)
                    .zIndex(1000)
                }
                
                Spacer()
            }
        }
    }
}

extension View {
    func errorToast(photoStore: PhotoStore) -> some View {
        self.modifier(ErrorToastModifier(photoStore: photoStore))
    }
}
