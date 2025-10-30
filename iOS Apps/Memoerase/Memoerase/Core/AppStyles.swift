//
//  AppStyles.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import SwiftUI

struct AppStyles {
    struct Colors {
        static let primary = Color(red: 0.41, green: 0.91, blue: 0.85) // Teal
        static let secondary = Color(red: 0.47, green: 0.67, blue: 0.98) // Soft blue
        
        // Swipe action renkleri
        static let deleteRed = Color(red: 1.0, green: 0.33, blue: 0.33) // Bright red
        static let keepGreen = Color(red: 0.13, green: 0.82, blue: 0.40) // Success green
        
        // Gradients
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [primary, secondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let deleteGradient = LinearGradient(
            gradient: Gradient(colors: [deleteRed, Color(red: 0.9, green: 0.2, blue: 0.2)]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // System uyumlu renkler
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let text = Color.primary
        static let secondaryText = Color.secondary
        static let lightText = Color.white
    }
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let statsNumber = Font.system(size: 28, weight: .bold, design: .rounded)
        static let statsLabel = Font.system(size: 14, weight: .medium, design: .rounded)
    }
    
    struct Dimensions {
        static let cornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 25
        static let buttonHeight: CGFloat = 50
        static let standardPadding: CGFloat = 20
        static let smallPadding: CGFloat = 12
        
        // Photo card dimensions
        static let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
        static let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    }
    
    struct Animations {
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let quick = Animation.easeOut(duration: 0.2)
        static let swipe = Animation.interpolatingSpring(stiffness: 300, damping: 25)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppStyles.Typography.headline)
            .foregroundColor(AppStyles.Colors.lightText)
            .frame(maxWidth: .infinity)
            .frame(height: AppStyles.Dimensions.buttonHeight)
            .background(AppStyles.Colors.primaryGradient)
            .cornerRadius(AppStyles.Dimensions.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppStyles.Animations.quick, value: configuration.isPressed)
            .shadow(color: AppStyles.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Card Container
struct CardContainer<Content: View>: View {
    let content: Content
    var backgroundColor: Color = AppStyles.Colors.background
    var cornerRadius: CGFloat = AppStyles.Dimensions.cornerRadius
    
    init(backgroundColor: Color = AppStyles.Colors.background,
         cornerRadius: CGFloat = AppStyles.Dimensions.cornerRadius,
         @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}




















































