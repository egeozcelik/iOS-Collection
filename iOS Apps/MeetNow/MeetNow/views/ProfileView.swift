//
//  ProfileView.swift
//  MeetNow
//
//  Created by Ege Özçelik on 14.08.2025.
//

import SwiftUI


struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFFCA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ProfileHeaderView(user: authManager.currentUser ?? User.mockUser) {
                            showingEditProfile = true
                        }
                        
                        ProfileStatsView(
                            eventsCreated: viewModel.eventsCreated,
                            eventsJoined: viewModel.eventsJoined,
                            averageRating: viewModel.averageRating
                        )
                        
                        ProfileMenuSection {
                            NavigationLink(destination: MyEventsView()) {
                                ProfileMenuItem(
                                    icon: "calendar.circle.fill",
                                    title: "My Events",
                                    subtitle: "Created and joined events",
                                    color: Color(hex: "4300FF")
                                )
                            }
                            
                            NavigationLink(destination: ConversationListView()) {
                                ProfileMenuItem(
                                    icon: "message.circle.fill",
                                    title: "Messages",
                                    subtitle: "Chat history",
                                    color: Color(hex: "0065F8")
                                )
                            }
                            
                            Button(action: { showingSettings = true }) {
                                ProfileMenuItem(
                                    icon: "gearshape.circle.fill",
                                    title: "Settings",
                                    subtitle: "Privacy & preferences",
                                    color: Color(hex: "00CAFF")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: ReportHistoryView()) {
                                ProfileMenuItem(
                                    icon: "exclamationmark.shield.fill",
                                    title: "Safety",
                                    subtitle: "Report & block users",
                                    color: Color(hex: "00FFDE")
                                )
                            }
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: { showingSignOutConfirmation = true }) {
                                HStack {
                                    if authManager.isSigningOut {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                            .scaleEffect(0.9)
                                        
                                        Text("Çıkış yapılıyor...")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.headline)
                                        
                                        Text("Çıkış Yap")
                                            .font(.headline)
                                    }
                                }
                                .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(authManager.isSigningOut)
                            .scaleEffect(authManager.isSigningOut ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3), value: authManager.isSigningOut)
                            
                            Button(action: { showingDeleteConfirmation = true }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                            .scaleEffect(0.9)
                                        
                                        Text("Hesap siliniyor...")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "trash.circle")
                                            .font(.subheadline)
                                        
                                        Text("Hesabı Sil")
                                            .font(.subheadline)
                                    }
                                }
                                .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.clear)
                            .disabled(authManager.isLoading)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: authManager.currentUser ?? User.mockUser)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Çıkış Yap", isPresented: $showingSignOutConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Oturumunuz sonlandırılacak. Aynı telefon numarası ile tekrar giriş yapabilirsiniz.")
        }
        .alert("Hesabı Sil", isPresented: $showingDeleteConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                authManager.deleteAccount { success in
                    if !success {
                        
                    }
                }
            }
        } message: {
            Text("DİKKAT: Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz. Tüm verileriniz ve etkinlikleriniz silinecek.")
        }
        .alert("İşlem Hatası", isPresented: .constant(!authManager.errorMessage.isEmpty && (authManager.isSigningOut || authManager.isLoading))) {
            Button("Tamam") {
                authManager.resetAuthState()
            }
        } message: {
            Text(authManager.errorMessage)
        }
        .onAppear {
            viewModel.loadProfile()
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                AsyncImage(url: URL(string: user.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "4300FF"), Color(hex: "00CAFF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Color(hex: "4300FF"))
                        .clipShape(Circle())
                }
                .offset(x: 35, y: 35)
            }
            
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(user.age) yaşında")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ProfileStatsView: View {
    let eventsCreated: Int
    let eventsJoined: Int
    let averageRating: Double
    
    var body: some View {
        HStack(spacing: 5) {
            StatCard(
                title: "Created",
                value: "\(eventsCreated)",
                gradient: [Color(hex: "4300FF"), Color(hex: "0065F8")]
            )
            
            StatCard(
                title: "Joined",
                value: "\(eventsJoined)",
                gradient: [Color(hex: "0065F8"), Color(hex: "00CAFF")]
            )
            
            StatCard(
                title: "Rating",
                value: String(format: "%.1f", averageRating),
                gradient: [Color(hex: "00CAFF"), Color(hex: "00FFDE")]
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProfileMenuSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            content
        }
        .padding(.horizontal)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EditProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var name: String
    @State private var age: String
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUpdating = false
    
    init(user: User) {
        self.user = user
        self._name = State(initialValue: user.name)
        self._age = State(initialValue: "\(user.age)")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFFCA")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Üst kısım - Profil Resmi (Ekranın yarısı)
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            PhotoPermissionManager.checkPhotoLibraryPermission { granted in
                                if granted {
                                    showingImagePicker = true
                                } else {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                            }
                        }) {
                            ZStack {
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 180, height: 180)
                                        .clipShape(Circle())
                                } else {
                                    AsyncImage(url: URL(string: user.profileImageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    .frame(width: 180, height: 180)
                                    .clipShape(Circle())
                                }
                                
                                // Camera overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .background(Color(hex: "4300FF"))
                                            .clipShape(Circle())
                                            .offset(x: -15, y: -15)
                                    }
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "4300FF"), Color(hex: "00CAFF")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4300FF").opacity(0.1), Color(hex: "00CAFF").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Alt kısım - Form alanları
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            // Ad Soyad
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ad Soyad")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Adınızı girin", text: $name)
                                    .font(.body)
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                !authManager.errorMessage.isEmpty && authManager.errorMessage.contains("Ad") ?
                                                Color.red : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .onChange(of: name) { newValue in
                                        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
                                        let filtered = String(newValue.unicodeScalars.filter { allowedCharacters.contains($0) })
                                        if filtered != newValue {
                                            name = String(filtered.prefix(25))
                                        } else if newValue.count > 25 {
                                            name = String(newValue.prefix(25))
                                        }
                                        
                                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            authManager.errorMessage = ""
                                        }
                                    }
                            }
                            
                            // Yaş
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yaş")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Yaşınızı girin", text: $age)
                                    .font(.body)
                                    .keyboardType(.numberPad)
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                !authManager.errorMessage.isEmpty && authManager.errorMessage.contains("Yaş") ?
                                                Color.red : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .onChange(of: age) { newValue in
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered != newValue {
                                            age = filtered
                                        }
                                        if let ageInt = Int(age), ageInt > 100 {
                                            age = "100"
                                        }
                                        
                                        if let ageInt = Int(newValue), ageInt >= 15 && ageInt <= 100 {
                                            authManager.errorMessage = ""
                                        }
                                    }
                            }
                            
                            // Telefon Numarası (Sadece görüntüleme)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Telefon Numarası")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(user.phoneNumber)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(16)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 16)
                                }
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Error Message
                            if !authManager.errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text(authManager.errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: "FAFFCA"))
                }
            }
            .dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        authManager.errorMessage = ""
                        dismiss()
                    }
                    .disabled(isUpdating)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        HStack(spacing: 8) {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4300FF")))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Kaydet")
                                .fontWeight(.semibold)
                                .foregroundColor(isFormValid ? Color(hex: "4300FF") : .gray)
                        }
                        .frame(minWidth: 80) // ✅ Minimum genişlik belirle
                    }
                    .disabled(!isFormValid || isUpdating)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .onChange(of: authManager.isLoading) { loading in
            isUpdating = loading
            
            // ✅ Profil güncelleme success state'ini kontrol et
            if !loading && authManager.profileUpdateSuccess {
                // Başarılı güncelleme sonrası 0.5 saniye bekle ve kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authManager.resetProfileUpdateState()
                    dismiss()
                }
            }
        }
        .onAppear {
            authManager.resetProfileUpdateState()
        }
    }
    
    private var isFormValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ageInt = Int(age) else { return false }
        
        return !trimmedName.isEmpty &&
               trimmedName.count >= 2 &&
               trimmedName.count <= 25 &&
               ageInt >= 15 &&
               ageInt <= 100 &&
               (trimmedName != user.name || ageInt != user.age || profileImage != nil)
    }
    
    private func saveProfile() {
        guard isFormValid else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ageInt = Int(age) else { return }
        
        authManager.updateUserProfile(
            name: trimmedName,
            age: ageInt,
            profileImage: profileImage
        )
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pushNotifications = true
    @State private var locationServices = true
    @State private var showOnMap = true
    @State private var autoJoinRadius = 2.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFFCA")
                    .ignoresSafeArea()
                
                List {
                    Section("Notifications") {
                        Toggle("Push Notifications", isOn: $pushNotifications)
                        Toggle("New Events Nearby", isOn: $showOnMap)
                    }
                    .listRowBackground(Color.white)
                    
                    Section("Privacy") {
                        Toggle("Location Services", isOn: $locationServices)
                        Toggle("Show on Map", isOn: $showOnMap)
                    }
                    .listRowBackground(Color.white)
                    
                    Section("Event Settings") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Auto-join radius: \(Int(autoJoinRadius)) km")
                                .font(.subheadline)
                            
                            Slider(value: $autoJoinRadius, in: 1...10, step: 1)
                                .tint(Color(hex: "4300FF"))
                        }
                    }
                    .listRowBackground(Color.white)
                    
                    Section("Support") {
                        Button("Contact Support") {}
                        Button("Privacy Policy") {}
                        Button("Terms of Service") {}
                    }
                    .listRowBackground(Color.white)
                    
                    Section("Danger Zone") {
                        Button("Delete Account") {}
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.white)
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MyEventsView: View {
    @StateObject private var viewModel = MyEventsViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color(hex: "FAFFCA")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("Events", selection: $selectedSegment) {
                    Text("Created").tag(0)
                    Text("Joined").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        let events = selectedSegment == 0 ? viewModel.createdEvents : viewModel.joinedEvents
                        
                        if events.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No events yet")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(events, id: \.id) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("My Events")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadEvents()
        }
    }
}

struct ReportHistoryView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAFFCA")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "4300FF"))
                
                Text("Stay Safe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Report inappropriate behavior or content to help keep our community safe.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    Button("Report a User") {}
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Block a User") {}
                        .font(.headline)
                        .foregroundColor(Color(hex: "4300FF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "4300FF"), lineWidth: 2)
                        )
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

class ProfileViewModel: ObservableObject {
    @Published var currentUser = User.mockUser
    @Published var eventsCreated = 5
    @Published var eventsJoined = 12
    @Published var averageRating = 4.8
    
    func loadProfile() {
        
    }
    
    func signOut() {
        print("Sign out")
    }
}

class MyEventsViewModel: ObservableObject {
    @Published var createdEvents: [EventModel] = []
    @Published var joinedEvents: [EventModel] = []
    
    func loadEvents() {
        createdEvents = [EventModel.mockEvent]
        joinedEvents = []
    }
}
