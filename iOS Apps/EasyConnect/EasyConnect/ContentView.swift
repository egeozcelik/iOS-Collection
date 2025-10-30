//
//  ContentView.swift
//  EasyConnect
//
//  Created by Ege Özçelik on 27.09.2025.
//

import SwiftUI
import Foundation
internal import Combine

// MARK: - Data Models
struct BusinessCard: Identifiable, Codable {
    let id = UUID()
    var name: String = ""
    var title: String = ""
    var company: String = ""
    var phone: String = ""
    var email: String = ""
    var website: String = ""
    var templateId: String = "modern"
    var backgroundColor: String = "#FFFFFF"
    var textColor: String = "#000000"
    var accentColor: String = "#007AFF"
    var createdAt: Date = Date()
}

struct CardTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let previewImageName: String
}

// MARK: - ViewModel
class BusinessCardViewModel: ObservableObject {
    @Published var currentCard = BusinessCard()
    @Published var savedCards: [BusinessCard] = []
    @Published var isCreatingCard = false
    
    let availableTemplates = [
        CardTemplate(id: "modern", name: "Modern", description: "Temiz ve minimalist tasarım", previewImageName: "modern_preview"),
        CardTemplate(id: "classic", name: "Klasik", description: "Geleneksel iş kartı düzeni", previewImageName: "classic_preview"),
        CardTemplate(id: "bold", name: "Cesur", description: "Canlı renkler ve büyük typography", previewImageName: "bold_preview"),
        CardTemplate(id: "elegant", name: "Zarif", description: "Sofistike ve profesyonel görünüm", previewImageName: "elegant_preview")
    ]
    
    func createNewCard() {
        currentCard = BusinessCard()
        isCreatingCard = true
    }
    
    func saveCard() {
        savedCards.append(currentCard)
        isCreatingCard = false
    }
    
    func cancelCardCreation() {
        currentCard = BusinessCard()
        isCreatingCard = false
    }
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var viewModel = BusinessCardViewModel()
    
    var body: some View {
        NavigationView {
            MainDashboardView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Main Dashboard
struct MainDashboardView: View {
    @EnvironmentObject var viewModel: BusinessCardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("EasyConnect")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Create your digital ID, Share with one touch, expand your network.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Current Card Section
            if !viewModel.savedCards.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Kartlarım")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.savedCards) { card in
                                CardPreviewView(card: card, isCompact: true)
                                    .frame(width: 280, height: 160)
                            }
                        }
                        .padding()
                    }
                }
                .padding(.bottom)
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Hızlı İşlemler")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    QuickActionCard(
                        icon: "plus.square.fill",
                        title: "Yeni Kart",
                        subtitle: "Kart oluştur",
                        color: .blue
                    ) {
                        viewModel.createNewCard()
                    }
                    
                    QuickActionCard(
                        icon: "square.and.arrow.up.fill",
                        title: "Paylaş",
                        subtitle: "Kartını paylaş",
                        color: .green
                    ) {
                        // Paylaşım işlemi
                    }
                    
                    QuickActionCard(
                        icon: "person.2.fill",
                        title: "Alınan Kartlar",
                        subtitle: "Koleksiyonun",
                        color: .orange
                    ) {
                        // Koleksiyon görüntüleme
                    }
                    
                    QuickActionCard(
                        icon: "gear.circle.fill",
                        title: "Ayarlar",
                        subtitle: "Uygulamayı özelleştir",
                        color: .purple
                    ) {
                        // Ayarlar
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.isCreatingCard) {
            CreateCardView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Card View - YENİ TEK EKRAN TASARIM
struct CreateCardView: View {
    @EnvironmentObject var viewModel: BusinessCardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CardPreviewView(card: viewModel.currentCard, isCompact: false)
                    .frame(width: 350, height: 200)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding()
               
                ScrollView {
                    VStack(spacing: 24) {
                        // Şablon Seçimi
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Şablon")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.availableTemplates) { template in
                                        TemplateSelectionCard(
                                            template: template,
                                            isSelected: viewModel.currentCard.templateId == template.id
                                        ) {
                                            viewModel.currentCard.templateId = template.id
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Kişisel Bilgiler
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Kişisel Bilgiler")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Ad Soyad",
                                    text: $viewModel.currentCard.name,
                                    placeholder: "Adınızı ve soyadınızı girin"
                                )
                                
                                CustomTextField(
                                    title: "Ünvan",
                                    text: $viewModel.currentCard.title,
                                    placeholder: "Pozisyonunuzu girin"
                                )
                                
                                CustomTextField(
                                    title: "Şirket",
                                    text: $viewModel.currentCard.company,
                                    placeholder: "Şirket adını girin"
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // İletişim Bilgileri
                        VStack(alignment: .leading, spacing: 16) {
                            Text("İletişim Bilgileri")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Telefon",
                                    text: $viewModel.currentCard.phone,
                                    placeholder: "Telefon numaranızı girin",
                                    keyboardType: .phonePad
                                )
                                
                                CustomTextField(
                                    title: "E-posta",
                                    text: $viewModel.currentCard.email,
                                    placeholder: "E-posta adresinizi girin",
                                    keyboardType: .emailAddress
                                )
                                
                                CustomTextField(
                                    title: "Website",
                                    text: $viewModel.currentCard.website,
                                    placeholder: "Web sitenizi girin",
                                    keyboardType: .URL
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Renk Seçimi
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Renk Teması")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ColorPickerSection()
                                .environmentObject(viewModel)
                                .padding(.horizontal)
                        }
                        
                        // Alt boşluk
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Yeni Kart Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        viewModel.cancelCardCreation()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        viewModel.saveCard()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.currentCard.name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Template Selection Card
struct TemplateSelectionCard: View {
    let template: CardTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Template Preview (placeholder)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 50)
                    .overlay(
                        Text("ABC")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    )
                
                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Picker Section
struct ColorPickerSection: View {
    @EnvironmentObject var viewModel: BusinessCardViewModel
    
    let predefinedColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#5AC8FA", "#AF52DE", "#FF2D92"
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Vurgu Rengi")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(predefinedColors, id: \.self) { colorHex in
                    Button(action: {
                        viewModel.currentCard.accentColor = colorHex
                    }) {
                        Circle()
                            .fill(Color(hex: colorHex) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .opacity(viewModel.currentCard.accentColor == colorHex ? 1 : 0)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
    }
}

// MARK: - Card Preview View
struct CardPreviewView: View {
    let card: BusinessCard
    let isCompact: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: card.backgroundColor) ?? .white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Content based on template
            switch card.templateId {
            case "modern":
                ModernCardLayout(card: card, isCompact: isCompact)
            case "classic":
                ClassicCardLayout(card: card, isCompact: isCompact)
            case "bold":
                BoldCardLayout(card: card, isCompact: isCompact)
            case "elegant":
                ElegantCardLayout(card: card, isCompact: isCompact)
            default:
                ModernCardLayout(card: card, isCompact: isCompact)
            }
        }
    }
}

// MARK: - Card Layouts
struct ModernCardLayout: View {
    let card: BusinessCard
    let isCompact: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
                Text(card.name.isEmpty ? "Ad Soyad" : card.name)
                    .font(isCompact ? .headline : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(card.name.isEmpty ? .gray : (Color(hex: card.textColor) ?? .black))
                
                Text(card.title.isEmpty ? "Ünvan" : card.title)
                    .font(isCompact ? .caption : .subheadline)
                    .foregroundColor(card.title.isEmpty ? .gray : (Color(hex: card.accentColor) ?? .blue))
                
                Text(card.company.isEmpty ? "Şirket" : card.company)
                    .font(isCompact ? .caption : .subheadline)
                    .foregroundColor(card.company.isEmpty ? .gray : .secondary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.email.isEmpty ? "email@ornek.com" : card.email)
                        .font(.caption)
                        .foregroundColor(card.email.isEmpty ? .gray : .secondary)
                    
                    Text(card.phone.isEmpty ? "+90 555 123 45 67" : card.phone)
                        .font(.caption)
                        .foregroundColor(card.phone.isEmpty ? .gray : .secondary)
                }
            }
            
            Spacer()
            
            // Accent element
            Circle()
                .fill(Color(hex: card.accentColor) ?? .blue)
                .frame(width: isCompact ? 40 : 60, height: isCompact ? 40 : 60)
                .opacity(0.2)
        }
        .padding(isCompact ? 12 : 20)
    }
}

struct ClassicCardLayout: View {
    let card: BusinessCard
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            VStack(spacing: isCompact ? 2 : 4) {
                Text(card.name.isEmpty ? "Ad Soyad" : card.name)
                    .font(isCompact ? .headline : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(card.name.isEmpty ? .gray : (Color(hex: card.textColor) ?? .black))
                
                Text(card.title.isEmpty ? "Ünvan" : card.title)
                    .font(isCompact ? .caption : .subheadline)
                    .foregroundColor(card.title.isEmpty ? .gray : .secondary)
                
                Text(card.company.isEmpty ? "Şirket" : card.company)
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(card.company.isEmpty ? .gray : (Color(hex: card.accentColor) ?? .blue))
            }
            
            Rectangle()
                .fill(Color(hex: card.accentColor) ?? .blue)
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            VStack(spacing: 2) {
                Text(card.email.isEmpty ? "email@ornek.com" : card.email)
                    .font(.caption)
                    .foregroundColor(card.email.isEmpty ? .gray : .secondary)
                
                Text(card.phone.isEmpty ? "+90 555 123 45 67" : card.phone)
                    .font(.caption)
                    .foregroundColor(card.phone.isEmpty ? .gray : .secondary)
                
                if !card.website.isEmpty {
                    Text(card.website)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(isCompact ? 12 : 20)
    }
}

struct BoldCardLayout: View {
    let card: BusinessCard
    let isCompact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: card.accentColor) ?? .blue)
                    .frame(width: isCompact ? 4 : 6, height: isCompact ? 30 : 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name.isEmpty ? "AD SOYAD" : card.name)
                        .font(isCompact ? .headline : .title2)
                        .fontWeight(.black)
                        .foregroundColor(card.name.isEmpty ? .gray : (Color(hex: card.textColor) ?? .black))
                    
                    Text((card.title.isEmpty ? "ÜNVAN" : card.title).uppercased())
                        .font(isCompact ? .caption : .caption)
                        .fontWeight(.bold)
                        .foregroundColor(card.title.isEmpty ? .gray : (Color(hex: card.accentColor) ?? .blue))
                }
                
                Spacer()
            }
            
            Text(card.company.isEmpty ? "Şirket Adı" : card.company)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(card.company.isEmpty ? .gray : .secondary)
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.email.isEmpty ? "email@ornek.com" : card.email)
                        .font(.caption)
                        .foregroundColor(card.email.isEmpty ? .gray : .secondary)
                    
                    Text(card.phone.isEmpty ? "+90 555 123 45 67" : card.phone)
                        .font(.caption)
                        .foregroundColor(card.phone.isEmpty ? .gray : .secondary)
                }
                Spacer()
            }
        }
        .padding(isCompact ? 12 : 20)
    }
}

struct ElegantCardLayout: View {
    let card: BusinessCard
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: isCompact ? 10 : 16) {
            HStack {
                Spacer()
                VStack(spacing: isCompact ? 4 : 6) {
                    Text(card.name.isEmpty ? "Ad Soyad" : card.name)
                        .font(isCompact ? .headline : .title2)
                        .fontWeight(.light)
                        .foregroundColor(card.name.isEmpty ? .gray : (Color(hex: card.textColor) ?? .black))
                    
                    Text(card.title.isEmpty ? "Ünvan" : card.title)
                        .font(isCompact ? .caption : .subheadline)
                        .fontWeight(.ultraLight)
                        .foregroundColor(card.title.isEmpty ? .gray : .secondary)
                        .italic()
                }
                Spacer()
            }
            
            Text(card.company.isEmpty ? "Şirket Adı" : card.company)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.medium)
                .foregroundColor(card.company.isEmpty ? .gray : (Color(hex: card.accentColor) ?? .blue))
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.email.isEmpty ? "email@ornek.com" : card.email)
                        .font(.caption2)
                        .foregroundColor(card.email.isEmpty ? .gray : .secondary)
                    
                    Text(card.phone.isEmpty ? "+90 555 123 45 67" : card.phone)
                        .font(.caption2)
                        .foregroundColor(card.phone.isEmpty ? .gray : .secondary)
                }
                Spacer()
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: card.accentColor) ?? .blue)
                    .frame(width: isCompact ? 20 : 30, height: isCompact ? 20 : 30)
                    .opacity(0.3)
            }
        }
        .padding(isCompact ? 12 : 20)
    }
}

// MARK: - Extensions
extension Color {
    init?(hex: String) {
        guard hex.hasPrefix("#"), hex.count == 7 else { return nil }
        
        let scanner = Scanner(string: String(hex.dropFirst()))
        var rgbValue: UInt64 = 0
        
        guard scanner.scanHexInt64(&rgbValue) else { return nil }
        
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}
