import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentStep: AuthStep = .phoneNumber
    @State private var isUserVerified = false
    @State private var isExistingUser = false
    
    @State private var phoneNumber = ""
    @State private var countryCode = "+90"
    
    @State private var verificationCode = ""
    
    @State private var fullName = ""
    @State private var age = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    
    @State private var showingSuccessAnimation = false
    
    var body: some View {
        ZStack {
            Image("loginbackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        Text("MeetNow")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text(currentStep.subtitle(isExistingUser: isExistingUser))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 60)
                    
                    AuthGlassContainer {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .phoneNumber:
                                PhoneNumberStepView(
                                    countryCode: $countryCode,
                                    phoneNumber: $phoneNumber,
                                    authManager: authManager
                                ) {
                                    sendVerificationCode()
                                }
                                
                            case .verification:
                                VerificationStepView(
                                    verificationCode: $verificationCode,
                                    phoneNumber: fullPhoneNumber,
                                    authManager: authManager,
                                    onVerify: {
                                        verifyCode()
                                    },
                                    onResend: {
                                        sendVerificationCode()
                                    }
                                )
                                
                            case .userInfo:
                                UserInfoStepView(
                                    fullName: $fullName,
                                    age: $age,
                                    profileImage: $profileImage,
                                    showingImagePicker: $showingImagePicker,
                                    authManager: authManager
                                ) {
                                    createUserProfile()
                                }
                            }
                        }
                        .padding(28)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
            .dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
            
            if showingSuccessAnimation {
                SuccessAnimationView(isExistingUser: isExistingUser)
                    .transition(.opacity)
            }
        }
        .onChange(of: authManager.isCodeSent) { isCodeSent in
            if isCodeSent {
                authManager.errorMessage = ""
                withAnimation(.easeInOut) {
                    currentStep = .verification
                }
            }
        }
        .onChange(of: isUserVerified) { verified in
            if verified {
                authManager.errorMessage = ""
                if !isExistingUser {
                    withAnimation(.easeInOut) {
                        currentStep = .userInfo
                    }
                } else {
                    withAnimation(.spring()) {
                        showingSuccessAnimation = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSuccessAnimation = false
                    }
                }
            }
        }
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn && isExistingUser {
                withAnimation(.spring()) {
                    showingSuccessAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showingSuccessAnimation = false
                }
            } else if isLoggedIn && !isExistingUser {
                withAnimation(.spring()) {
                    showingSuccessAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showingSuccessAnimation = false
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }
    
    private var fullPhoneNumber: String {
        return countryCode + phoneNumber
    }
    
    private func sendVerificationCode() {
        authManager.errorMessage = ""
        authManager.sendVerificationCode(phoneNumber: fullPhoneNumber)
    }
    
    private func verifyCode() {
        authManager.errorMessage = ""
        authManager.verifyCode(verificationCode: verificationCode) { success, userExists in
            if success {
                isUserVerified = true
                isExistingUser = userExists
                
                if userExists {
                    print("✅ Mevcut kullanıcı giriş yaptı")
                } else {
                    print("🆕 Yeni kullanıcı - profil oluşturma ekranına yönlendiriliyor")
                }
            }
        }
    }
    
    private func createUserProfile() {
        guard let ageInt = Int(age) else {
            return
        }
        
        authManager.errorMessage = ""
        authManager.createUserProfile(
            name: fullName,
            age: ageInt,
            profileImage: profileImage
        )
    }
}

enum AuthStep {
    case phoneNumber
    case verification
    case userInfo
    
    func subtitle(isExistingUser: Bool = false) -> String {
        switch self {
        case .phoneNumber:
            return "Telefon numaranızı girerek başlayın"
        case .verification:
            return "Size gönderilen doğrulama kodunu girin"
        case .userInfo:
            return "Profilinizi tamamlayın"
        }
    }
}

struct PhoneNumberStepView: View {
    @Binding var countryCode: String
    @Binding var phoneNumber: String
    @ObservedObject var authManager: AuthenticationManager
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Telefon Numaranız")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextField("Kod", text: $countryCode)
                        .font(.headline)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "4300FF").opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 80)
                        .keyboardType(.phonePad)
                    
                    TextField("5XX XXX XX XX", text: $phoneNumber)
                        .font(.headline)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "4300FF").opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()
                        .onChange(of: phoneNumber) { newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == " " }
                            if filtered != newValue {
                                phoneNumber = filtered
                            }
                        }
                }
                
                if authManager.loginCooldownRemaining > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Tekrar deneme: \(Int(authManager.loginCooldownRemaining)) saniye")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if authManager.loginAttemptsRemaining < 5 && authManager.loginCooldownRemaining == 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Kalan deneme hakkı: \(authManager.loginAttemptsRemaining)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if !authManager.errorMessage.isEmpty {
                    ErrorMessageView(message: authManager.errorMessage)
                }
            }
            
            Button(action: onContinue) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Doğrulama Kodu Gönder")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isButtonEnabled ?
                LinearGradient(
                    colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: isButtonEnabled ? Color(hex: "4300FF").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .disabled(!isButtonEnabled)
            .scaleEffect(authManager.isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: authManager.isLoading)
        }
    }
    
    private var isButtonEnabled: Bool {
        return phoneNumber.count >= 10 &&
               !authManager.isLoading &&
               authManager.loginCooldownRemaining == 0 &&
               authManager.loginAttemptsRemaining > 0
    }
}

struct VerificationStepView: View {
    @Binding var verificationCode: String
    let phoneNumber: String
    @ObservedObject var authManager: AuthenticationManager
    let onVerify: () -> Void
    let onResend: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Doğrulama Kodu")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 8) {
                Text(phoneNumber)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                
                Text("numarasına gönderilen 6 haneli kodu girin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("000000", text: $verificationCode)
                    .textContentType(.oneTimeCode)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                verificationCode.count == 6 ?
                                LinearGradient(
                                    colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: verificationCode) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            verificationCode = String(filtered.prefix(6))
                        }
                    }
                
                if authManager.remainingAttempts < 3 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Kalan deneme hakkı: \(authManager.remainingAttempts)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if !authManager.errorMessage.isEmpty {
                    ErrorMessageView(message: authManager.errorMessage)
                }
            }
            
            VStack(spacing: 12) {
                Button(action: onVerify) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Doğrula")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    (verificationCode.count == 6 && authManager.remainingAttempts > 0) ?
                    LinearGradient(
                        colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: (verificationCode.count == 6 && authManager.remainingAttempts > 0) ? Color(hex: "4300FF").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                .disabled(verificationCode.count != 6 || authManager.isLoading || authManager.remainingAttempts <= 0)
                .scaleEffect(authManager.isLoading ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: authManager.isLoading)
                
                if authManager.cooldownTimeRemaining > 0 {
                    Text("Kodu tekrar gönder (\(Int(authManager.cooldownTimeRemaining))s)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(8)
                } else {
                    Button("Kodu tekrar gönder", action: onResend)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4300FF"))
                        .padding(8)
                }
            }
        }
    }
}

struct UserInfoStepView: View {
    @Binding var fullName: String
    @Binding var age: String
    @Binding var profileImage: UIImage?
    @Binding var showingImagePicker: Bool
    @ObservedObject var authManager: AuthenticationManager
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Profil Bilgileri")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 20) {
                Button(action: { showingImagePicker = true }) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color(hex: "00CAFF").opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00CAFF").opacity(0.2), Color(hex: "00FFDE").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "00CAFF"))
                                    
                                    Text("Fotoğraf Ekle")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "00CAFF"))
                                        .fontWeight(.medium)
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "00CAFF").opacity(0.5), lineWidth: 2)
                            )
                    }
                }
                
                TextField("Ad Soyad", text: $fullName)
                    .font(.headline)
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "00CAFF").opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: fullName) { newValue in
                        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
                        let filtered = String(newValue.unicodeScalars.filter { allowedCharacters.contains($0) })
                        if filtered != newValue {
                            fullName = String(filtered.prefix(25))
                        } else if newValue.count > 25 {
                            fullName = String(newValue.prefix(25))
                        }
                    }
                
                TextField("Yaş", text: $age)
                    .font(.headline)
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "00CAFF").opacity(0.3), lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: age) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            age = filtered
                        }
                        if let ageInt = Int(age), ageInt > 100 {
                            age = "100"
                        }
                    }
                
                if !authManager.errorMessage.isEmpty {
                    ErrorMessageView(message: authManager.errorMessage)
                }
            }
            
            Button(action: onComplete) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Kayıt Tamamla")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isFormValid ?
                LinearGradient(
                    colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: isFormValid ? Color(hex: "00CAFF").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .disabled(!isFormValid || authManager.isLoading)
            .scaleEffect(authManager.isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: authManager.isLoading)
        }
    }
    
    private var isFormValid: Bool {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ageInt = Int(age) else { return false }
        
        return !trimmedName.isEmpty &&
               trimmedName.count >= 2 &&
               trimmedName.count <= 25 &&
               ageInt >= 15 &&
               ageInt <= 100
    }
}

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            Text(message)
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

struct SuccessAnimationView: View {
    let isExistingUser: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: isExistingUser ? "person.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isExistingUser ? .blue : .green)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text(isExistingUser ? "Hoş Geldiniz!" : "Kayıt Başarılı!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                if isExistingUser {
                    Text("Hesabınıza giriş yapıldı")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                } else {
                    Text("Profiliniz oluşturuldu")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true // ✅ Editing enable
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // ✅ Edited image varsa onu kullan, yoksa original
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
