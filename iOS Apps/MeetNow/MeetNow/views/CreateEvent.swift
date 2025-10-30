//
//  CreateEvent.swift
//  MeetNow
//  Enhanced version with participant slider and location privacy
//

import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFFCA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        StepIndicator(currentStep: viewModel.currentStep, totalSteps: 4)
                            .padding(.horizontal)
                        
                        switch viewModel.currentStep {
                        case 1:
                            TimeSelectionStep(viewModel: viewModel)
                        case 2:
                            LocationSelectionStep(viewModel: viewModel)
                        case 3:
                            EventDetailsStep(viewModel: viewModel)
                        case 4:
                            EventSummaryStep(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    Spacer()
                    
                    NavigationButtons(viewModel: viewModel) {
                        withAnimation {
                            if viewModel.currentStep == 4 {
                                viewModel.createEvent()
                                dismiss()
                            } else {
                                viewModel.nextStep()
                            }
                        }
                    } onBack: {
                        withAnimation {
                            viewModel.previousStep()
                        }
                    }
                }
                
                // Loading overlay
                if viewModel.isCreating {
                    CreateEventLoadingView()
                }
            }
        }
        .onAppear {
            viewModel.setEventManager(eventManager)
            viewModel.setLocationManager(locationManager)
        }
        .navigationTitle("Etkinlik Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
                .disabled(viewModel.isCreating)
            }
        }
        .alert("Konum Gerekli", isPresented: .constant(viewModel.locationError != nil)) {
            Button("Tamam") {
                viewModel.locationError = nil
            }
            Button("Konum İzni Ver") {
                locationManager.requestLocationPermission()
                viewModel.locationError = nil
            }
        } message: {
            Text(viewModel.locationError ?? "")
        }
    }
}

struct NavigationButtons: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 1 {
                Button("Geri") {
                    onBack()
                }
                .font(.headline)
                .foregroundColor(Color(hex: "4300FF"))
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "4300FF"), lineWidth: 2)
                )
                .disabled(viewModel.isCreating)
            }
            
            Button(viewModel.currentStep == 4 ? "Etkinlik Oluştur" : "İleri") {
                onNext()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                viewModel.canProceed && !viewModel.isCreating ?
                LinearGradient(
                    colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!viewModel.canProceed || viewModel.isCreating)
        }
        .padding()
        .background(Color(hex: "FAFFCA"))
    }
}

struct CreateEventLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Etkinlik oluşturuluyor...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Yakındaki kişiler bilgilendirilecek")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step Indicator (unchanged)
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ?
                          LinearGradient(colors: [Color(hex: "4300FF"), Color(hex: "0065F8")], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 12, height: 12)
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color(hex: "4300FF") : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Time Selection (unchanged)
struct TimeSelectionStep: View {
    @ObservedObject var viewModel: CreateEventViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ne zaman buluşmak istiyorsunuz?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                TimeOptionCard(
                    title: "Şu An",
                    subtitle: "Hemen başla",
                    icon: "clock.fill",
                    isSelected: viewModel.selectedTimeType == .immediate
                ) {
                    viewModel.selectedTimeType = .immediate
                }
                
                TimeOptionCard(
                    title: "Bugün - Esnek",
                    subtitle: "Bugün herhangi bir zaman",
                    icon: "calendar.badge.clock",
                    isSelected: viewModel.selectedTimeType == .flexible
                ) {
                    viewModel.selectedTimeType = .flexible
                }
                
                TimeOptionCard(
                    title: "Belirli saatten sonra",
                    subtitle: "Başlangıç saati belirle",
                    icon: "clock.arrow.circlepath",
                    isSelected: viewModel.selectedTimeType == .afterTime("")
                ) {
                    viewModel.selectedTimeType = .afterTime("19:00")
                }
                
                TimeOptionCard(
                    title: "Belirli tarih ve saat",
                    subtitle: "İleri bir zamana planla",
                    icon: "calendar",
                    isSelected: viewModel.selectedTimeType == .specificTime
                ) {
                    viewModel.selectedTimeType = .specificTime
                }
            }
            .padding(.horizontal)
            
            if case .afterTime(_) = viewModel.selectedTimeType {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saat seçin:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                }
            }
            
            if case .specificTime = viewModel.selectedTimeType {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tarih ve saat seçin:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    DatePicker("", selection: $viewModel.selectedDateTime, in: Date()...Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct TimeOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(hex: "4300FF"))
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color(hex: "4300FF") : Color(hex: "4300FF").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected ?
                LinearGradient(colors: [Color(hex: "4300FF"), Color(hex: "0065F8")], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Location Selection
struct LocationSelectionStep: View {
    @ObservedObject var viewModel: CreateEventViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nerede buluşacaksınız?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                LocationOptionCard(
                    title: "Mevcut Konumum",
                    subtitle: "Şu anki konumumu kullan",
                    icon: "location.fill",
                    isSelected: viewModel.useCurrentLocation && !viewModel.isLocationHidden
                ) {
                    viewModel.useCurrentLocation = true
                    viewModel.searchLocation = false
                    viewModel.isLocationHidden = false
                }
                
                LocationOptionCard(
                    title: "Konum Ara",
                    subtitle: "Belirli bir yer bul",
                    icon: "magnifyingglass",
                    isSelected: viewModel.searchLocation
                ) {
                    viewModel.useCurrentLocation = false
                    viewModel.searchLocation = true
                    viewModel.isLocationHidden = false
                }
                
                // NEW: Hidden location option
                LocationOptionCard(
                    title: "Gizli Konum",
                    subtitle: "Konum belirtilmesin (gizlilik)",
                    icon: "eye.slash.fill",
                    isSelected: viewModel.isLocationHidden
                ) {
                    viewModel.useCurrentLocation = true // Use current but hide it
                    viewModel.searchLocation = false
                    viewModel.isLocationHidden = true
                }
            }
            .padding(.horizontal)
            
            if viewModel.searchLocation {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Konum ara:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    SearchTextField(text: $viewModel.locationSearchText, placeholder: "Konum adı girin")
                        .padding(.horizontal)
                    
                    if !viewModel.locationSearchText.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.searchResults, id: \.id) { location in
                                LocationResultCard(location: location) {
                                    viewModel.selectedLocation = location
                                    viewModel.locationSearchText = location.name
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            if viewModel.isLocationHidden {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Gizlilik Bilgisi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Etkinliğiniz yakındaki kişilere gösterilecek ancak tam konum gizli kalacak. Katılımcılar etkinliğe katıldıktan sonra detaylı konum bilgisini alabilecek.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 24)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

struct LocationOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(hex: "00CAFF"))
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color(hex: "00CAFF") : Color(hex: "00CAFF").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected ?
                LinearGradient(colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

struct LocationResultCard: View {
    let location: Location
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(hex: "00CAFF"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(location.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Event Details with Participant Slider
struct EventDetailsStep: View {
    @ObservedObject var viewModel: CreateEventViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Etkinlik Detayları")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                // Icon selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("İkon seçin")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(EventIcon.allCases, id: \.self) { icon in
                            IconSelectionCard(
                                icon: icon,
                                isSelected: viewModel.selectedIcon == icon
                            ) {
                                viewModel.selectedIcon = icon
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Event title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Etkinlik Başlığı")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Etkinliğiniz ne hakkında?", text: $viewModel.eventTitle)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Açıklama")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("İnsanlara ne bekleyeceklerini anlatın...", text: $viewModel.eventDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                // NEW: Enhanced Participant Selection with Slider
                VStack(alignment: .leading, spacing: 16) {
                    Text("Kaç kişi katılabilir?")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Unlimited option
                        ParticipantOptionCard(
                            title: "Sınırsız",
                            subtitle: "Herkes katılabilir",
                            icon: "infinity",
                            isSelected: viewModel.isUnlimitedParticipants
                        ) {
                            viewModel.isUnlimitedParticipants = true
                            viewModel.maxParticipants = 0
                        }
                        
                        // Limited option with slider
                        VStack(spacing: 12) {
                            ParticipantOptionCard(
                                title: "Sınırlı",
                                subtitle: "Maksimum katılımcı sayısı belirle",
                                icon: "person.2.fill",
                                isSelected: !viewModel.isUnlimitedParticipants
                            ) {
                                viewModel.isUnlimitedParticipants = false
                                if viewModel.maxParticipants == 0 {
                                    viewModel.maxParticipants = 4 // Default value
                                }
                            }
                            
                            if !viewModel.isUnlimitedParticipants {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Maksimum: \(viewModel.maxParticipants) kişi")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text("(Sen dahil)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("2")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Slider(
                                            value: Binding(
                                                get: { Double(viewModel.maxParticipants) },
                                                set: { viewModel.maxParticipants = Int($0) }
                                            ),
                                            in: 2...10,
                                            step: 1
                                        )
                                        .tint(Color(hex: "00CAFF"))
                                        
                                        Text("10")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Visual participant indicator
                                    HStack(spacing: 4) {
                                        ForEach(1...min(viewModel.maxParticipants, 10), id: \.self) { index in
                                            Circle()
                                                .fill(index == 1 ? Color(hex: "4300FF") : Color(hex: "00CAFF"))
                                                .frame(width: 8, height: 8)
                                        }
                                        
                                        if viewModel.maxParticipants > 10 {
                                            Text("+\(viewModel.maxParticipants - 10)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding()
                                .background(Color(hex: "00CAFF").opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ParticipantOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(hex: "00CAFF"))
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color(hex: "00CAFF") : Color(hex: "00CAFF").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected ?
                LinearGradient(colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IconSelectionCard: View {
    let icon: EventIcon
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon.systemName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : Color(hex: "4300FF"))
                .frame(width: 50, height: 50)
                .background(
                    isSelected ?
                    AnyShapeStyle(LinearGradient(colors: [Color(hex: "4300FF"), Color(hex: "0065F8")], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                    AnyShapeStyle(Color(hex: "4300FF").opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color(hex: "4300FF").opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Event Summary
struct EventSummaryStep: View {
    @ObservedObject var viewModel: CreateEventViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Etkinlik Özeti")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                SummaryCard(
                    icon: "clock.fill",
                    title: "Zaman",
                    value: viewModel.timeDisplayText,
                    gradient: [Color(hex: "4300FF"), Color(hex: "0065F8")]
                )
                
                SummaryCard(
                    icon: viewModel.isLocationHidden ? "eye.slash.fill" : "location.fill",
                    title: "Konum",
                    value: viewModel.locationDisplayText,
                    gradient: [Color(hex: "00CAFF"), Color(hex: "00FFDE")]
                )
                
                SummaryCard(
                    icon: viewModel.selectedIcon.systemName,
                    title: "Etkinlik",
                    value: viewModel.eventTitle,
                    gradient: [Color(hex: "4300FF"), Color(hex: "00CAFF")]
                )
                
                SummaryCard(
                    icon: viewModel.isUnlimitedParticipants ? "infinity" : "person.2.fill",
                    title: "Katılımcılar",
                    value: viewModel.participantDisplayText,
                    gradient: [Color(hex: "0065F8"), Color(hex: "00FFDE")]
                )
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Açıklama")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text(viewModel.eventDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
            
            // Final confirmation note
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Etkinlik oluşturulduktan sonra")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 50km çapındaki kişiler etkinliğinizi görebilecek")
                    Text("• Katılım istekleri geldiğinde bildirim alacaksınız")
                    Text("• Etkinliği istediğiniz zaman iptal edebilirsiniz")
                    
                    if viewModel.isLocationHidden {
                        Text("• Konum gizli olacak, katılımcılar sonradan öğrenecek")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced ViewModel
class CreateEventViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var selectedTimeType: TimeType = .immediate
    @Published var selectedTime = Date()
    @Published var selectedDateTime = Date()
    
    // Enhanced location options
    @Published var useCurrentLocation = true
    @Published var searchLocation = false
    @Published var isLocationHidden = false  // NEW
    @Published var locationSearchText = ""
    @Published var selectedLocation: Location?
    
    @Published var selectedIcon: EventIcon = .coffee
    @Published var eventTitle = ""
    @Published var eventDescription = ""
    
    // Enhanced participant options
    @Published var maxParticipants = 4
    @Published var isUnlimitedParticipants = false  // NEW
    
    // State management
    @Published var isCreating = false
    @Published var locationError: String?
    
    private var eventManager: EventManager?
    private var locationManager: LocationManager?
    
    let searchResults = [
        Location(id: "1", name: "Konak Meydanı", latitude: 38.4237, longitude: 27.1428, address: "Konak, İzmir"),
        Location(id: "2", name: "Alsancak Kordon", latitude: 38.4378, longitude: 27.1463, address: "Alsancak, İzmir"),
        Location(id: "3", name: "Kadifekale", latitude: 38.4046, longitude: 27.1384, address: "Kadifekale, İzmir"),
        Location(id: "4", name: "Kemeraltı Çarşısı", latitude: 38.4192, longitude: 27.1287, address: "Kemeraltı, İzmir"),
        Location(id: "5", name: "Tarihi Asansör", latitude: 38.4067, longitude: 27.1420, address: "Balçova, İzmir")
    ]
    
    func setEventManager(_ eventManager: EventManager) {
        self.eventManager = eventManager
    }
    
    func setLocationManager(_ locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 1:
            return true
        case 2:
            if isLocationHidden || useCurrentLocation {
                return locationManager?.hasValidLocation ?? false
            }
            return selectedLocation != nil
        case 3:
            return !eventTitle.isEmpty && !eventDescription.isEmpty
        case 4:
            return true
        default:
            return false
        }
    }
    
    var timeDisplayText: String {
        switch selectedTimeType {
        case .immediate:
            return "Şu anda"
        case .flexible:
            return "Bugün - Esnek saat"
        case .afterTime(_):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Bugün \(formatter.string(from: selectedTime))'den sonra"
        case .specificTime:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: selectedDateTime)
        }
    }
    
    var locationDisplayText: String {
        if isLocationHidden {
            return "Gizli konum (yaklaşık alan gösterilecek)"
        } else if useCurrentLocation {
            return "Mevcut konum"
        } else if let location = selectedLocation {
            return location.name
        } else {
            return "Konum seçilmedi"
        }
    }
    
    var participantDisplayText: String {
        if isUnlimitedParticipants {
            return "Sınırsız katılımcı"
        } else {
            return "Maksimum \(maxParticipants) kişi"
        }
    }
    
    func nextStep() {
        // Validation before proceeding
        if currentStep == 2 {
            // Check location requirements
            if (useCurrentLocation || isLocationHidden) && !(locationManager?.hasValidLocation ?? false) {
                locationError = "Konum bilgisi gerekli. Lütfen konum iznini verin."
                return
            }
        }
        
        if currentStep < 4 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func createEvent() {
        guard let eventManager = eventManager else {
            locationError = "Event Manager bulunamadı"
            return
        }
        
        guard let locationManager = locationManager else {
            locationError = "Location Manager bulunamadı"
            return
        }
        
        guard locationManager.hasValidLocation else {
            locationError = "Konum bilgisi gerekli"
            return
        }
        
        isCreating = true
        locationError = nil
        
        // Convert unlimited to 0 for database
        let finalMaxParticipants = isUnlimitedParticipants ? 0 : maxParticipants
        
        eventManager.createEvent(
            title: eventTitle,
            description: eventDescription,
            icon: selectedIcon,
            timeType: selectedTimeType,
            selectedTime: selectedTime,
            selectedDateTime: selectedDateTime,
            useCurrentLocation: useCurrentLocation,
            selectedLocation: selectedLocation,
            maxParticipants: finalMaxParticipants,
            isLocationHidden: isLocationHidden
        )
        
        print("🎉 Etkinlik oluşturuluyor: \(eventTitle)")
        print("📍 Konum gizli: \(isLocationHidden)")
        print("👥 Max katılımcı: \(finalMaxParticipants) (sınırsız: \(isUnlimitedParticipants))")
    }
}
