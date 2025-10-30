//
//  Extension.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import SwiftUI

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }
        
        return "Just now"
    }
    
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Int64 Extensions (File Size)
extension Int64 {
    func formatAsFileSize() -> String {
        let bytes = Double(self)
        
        if bytes >= 1_073_741_824 { // 1 GB
            return String(format: "%.1f GB", bytes / 1_073_741_824)
        } else if bytes >= 1_048_576 { // 1 MB
            return String(format: "%.1f MB", bytes / 1_048_576)
        } else if bytes >= 1024 { // 1 KB
            return String(format: "%.1f KB", bytes / 1024)
        } else {
            return "\(Int(bytes)) bytes"
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppStyles.Colors.background)
            .cornerRadius(AppStyles.Dimensions.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
