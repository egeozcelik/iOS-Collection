import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication

class AuthenticationManager: ObservableObject {
    
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var verificationID: String?
    @Published var isCodeSent = false
    @Published var isSigningOut = false
    
    @Published var profileUpdateSuccess = false
   
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private let maxVerificationAttempts = 3
    private let cooldownPeriod: TimeInterval = 60
    private let maxLoginAttempts = 5
    private let loginCooldownPeriod: TimeInterval = 300
    
    @Published var remainingAttempts = 3
    @Published var cooldownTimeRemaining: TimeInterval = 0
    @Published var loginAttemptsRemaining = 5
    @Published var loginCooldownRemaining: TimeInterval = 0
    
    private var cooldownTimer: Timer?
    private var loginCooldownTimer: Timer?
    
    init() {
        loadPersistedAttempts()
        setupAuthStateListener()
        checkInitialAuthState()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        cooldownTimer?.invalidate()
        loginCooldownTimer?.invalidate()
        cooldownTimer = nil
        loginCooldownTimer = nil     
    }
    private func generateMockProfileImage() -> String {
            let randomId = Int.random(in: 200...999)
            return "https://picsum.photos/400/400?random=\(randomId)"
        }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let firebaseUser = user {
                    if self?.currentUser == nil && self?.isLoading == false {
                        print("🔄 Auth state değişti - kullanıcı kontrol ediliyor: \(firebaseUser.uid)")
                        self?.fetchUserData(uid: firebaseUser.uid)
                    }
                } else {
                    print("👋 Auth state değişti - kullanıcı çıkış yaptı")
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func checkInitialAuthState() {
        if let user = Auth.auth().currentUser {
            fetchUserData(uid: user.uid)
        }
    }
    
    func sendVerificationCode(phoneNumber: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            errorMessage = "Geçersiz telefon numarası formatı. Lütfen +90 5XX XXX XX XX formatında girin."
            return
        }
        
        guard loginAttemptsRemaining > 0 else {
            errorMessage = "Çok fazla giriş denemesi. \(Int(loginCooldownRemaining)) saniye bekleyin."
            return
        }
        
        guard cooldownTimeRemaining == 0 else {
            errorMessage = "Tekrar kod göndermek için \(Int(cooldownTimeRemaining)) saniye bekleyin."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let formattedPhone = formatPhoneNumber(phoneNumber)
        
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleAuthError(error)
                    self?.decrementLoginAttempts()
                    return
                }
                
                guard let verificationID = verificationID else {
                    self?.errorMessage = "Doğrulama kodu gönderilemedi. Lütfen tekrar deneyin."
                    self?.decrementLoginAttempts()
                    return
                }
                
                self?.verificationID = verificationID
                self?.isCodeSent = true
                self?.startCooldown()
                self?.resetVerificationAttempts()
                
                print("✅ Doğrulama kodu gönderildi: \(formattedPhone)")
            }
        }
    }
    
    func verifyCode(verificationCode: String, completion: @escaping (Bool, Bool) -> Void) {
        guard let verificationID = verificationID else {
            errorMessage = "Doğrulama kodu bulunamadı. Lütfen tekrar kod isteyin."
            completion(false, false)
            return
        }
        
        guard remainingAttempts > 0 else {
            errorMessage = "Çok fazla yanlış kod girişi. Lütfen yeni kod isteyin."
            completion(false, false)
            return
        }
        
        guard validateVerificationCode(verificationCode) else {
            completion(false, false)
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleAuthError(error)
                    self?.decrementVerificationAttempts()
                    completion(false, false)
                    return
                }
                
                guard let firebaseUser = result?.user else {
                    self?.errorMessage = "Doğrulama başarısız. Lütfen tekrar deneyin."
                    completion(false, false)
                    return
                }
                
                print("✅ Firebase authentication başarılı: \(firebaseUser.uid)")
                
                self?.checkIfUserExistsInFirestore(uid: firebaseUser.uid) { userExists in
                    DispatchQueue.main.async {
                        if userExists {
                            self?.fetchUserDataForLogin(uid: firebaseUser.uid)
                            completion(true, true)
                        } else {
                            completion(true, false)
                        }
                    }
                }
            }
        }
    }
    
    func createUserProfile(name: String, age: Int, profileImage: UIImage? = nil) {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        guard validateUserProfileInput(name: name, age: age) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("📝 Kullanıcı profili oluşturuluyor: \(name), \(age) yaş")
        let mockProfileURL = generateMockProfileImage()
        createUserInDatabase(
            uid: firebaseUser.uid,
            phoneNumber: firebaseUser.phoneNumber ?? "",
            name: name,
            age: age,
            profileImage: mockProfileURL
        )
    }
    
    private func validateVerificationCode(_ verificationCode: String) -> Bool {
        if verificationCode.isEmpty {
            errorMessage = "Doğrulama kodu boş olamaz"
            return false
        }
        
        if verificationCode.count != 6 {
            errorMessage = "Doğrulama kodu 6 haneli olmalıdır"
            return false
        }
        
        if !verificationCode.allSatisfy({ $0.isNumber }) {
            errorMessage = "Doğrulama kodu sadece rakam içermelidir"
            return false
        }
        
        return true
    }
    
    private func validateUserProfileInput(name: String, age: Int) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "Ad soyad boş olamaz"
            return false
        }
        
        if trimmedName.count < 2 {
            errorMessage = "Ad soyad en az 2 karakter olmalıdır"
            return false
        }
        
        if trimmedName.count > 25 {
            errorMessage = "Ad soyad en fazla 25 karakter olabilir"
            return false
        }
        
        let allowedCharacterSet = CharacterSet.letters.union(.whitespaces)
        if !trimmedName.unicodeScalars.allSatisfy({ allowedCharacterSet.contains($0) }) {
            errorMessage = "Ad soyad sadece harf ve boşluk içerebilir"
            return false
        }
        
        if age < 15 || age > 100 {
            errorMessage = "Yaş 15-100 arasında olmalıdır"
            return false
        }
        
        return true
    }
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        let turkeyPattern = "^(\\+90|0)?5[0-9]{9}$"
        let internationalPattern = "^\\+[1-9]\\d{1,14}$"
        
        let turkeyRegex = try? NSRegularExpression(pattern: turkeyPattern)
        let internationalRegex = try? NSRegularExpression(pattern: internationalPattern)
        
        let range = NSRange(location: 0, length: cleanNumber.utf16.count)
        
        return turkeyRegex?.firstMatch(in: cleanNumber, options: [], range: range) != nil ||
               internationalRegex?.firstMatch(in: cleanNumber, options: [], range: range) != nil
    }
    
    private func createUserInDatabase(
        uid: String,
        phoneNumber: String,
        name: String,
        age: Int,
        profileImage: String
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        saveUserToFirestore(
            uid: uid,
            phoneNumber: phoneNumber,
            name: trimmedName,
            age: age,
            profileImageURL: profileImage
        )
    }
    
    private func checkIfUserExistsInFirestore(uid: String, completion: @escaping (Bool) -> Void) {
        print("🔍 Firestore'da kullanıcı kontrol ediliyor: \(uid)")
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("❌ Kullanıcı varlık kontrolü hatası: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                let name = data["name"] as? String ?? ""
                let phoneNumber = data["phoneNumber"] as? String ?? ""
                
                if !name.isEmpty && !phoneNumber.isEmpty {
                    print("✅ Kullanıcı Firestore'da mevcut ve verileri tam")
                    completion(true)
                } else {
                    print("⚠️ Kullanıcı Firestore'da var ama verileri eksik")
                    completion(false)
                }
            } else {
                print("ℹ️ Kullanıcı Firestore'da yok")
                completion(false)
            }
        }
    }
    
    private func saveUserToFirestore(
        uid: String,
        phoneNumber: String,
        name: String,
        age: Int,
        profileImageURL: String
    ) {
        let userData: [String: Any] = [
            "name": name,
            "phoneNumber": phoneNumber,
            "profileImageURL": profileImageURL,
            "age": age,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "isActive": true,
            "deviceToken": "",
            "totalEventsCreated": 0,
            "totalEventsJoined": 0,
            "averageRating": 0.0,
            "lastLoginAt": Timestamp()
        ]
        
        print("💾 Firestore'a kullanıcı kaydediliyor: \(name)")
        
        db.collection("users").document(uid).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Kullanıcı kaydedilemedi: \(error.localizedDescription)"
                    print("❌ Firestore kayıt hatası: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Kullanıcı başarıyla Firestore'a kaydedildi")
                
                let user = User(
                    id: uid,
                    name: name,
                    phoneNumber: phoneNumber,
                    profileImageURL: profileImageURL,
                    age: age
                )
                
                self?.currentUser = user
                self?.isLoggedIn = true
                self?.resetAuthState()
                self?.resetAllAttempts()
                
                print("🎉 Kullanıcı giriş işlemi tamamlandı: \(user.name)")
            }
        }
    }
    
    private func fetchUserDataForLogin(uid: String) {
        print("📋 Login için kullanıcı verileri Firestore'dan alınıyor: \(uid)")
        
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Kullanıcı bilgileri alma hatası: \(error.localizedDescription)")
                    self?.errorMessage = "Kullanıcı bilgileri alınamadı: \(error.localizedDescription)"
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    print("❌ Kullanıcı dokümanı Firestore'da bulunamadı")
                    self?.errorMessage = "Kullanıcı bilgileri bulunamadı"
                    return
                }
                
                guard let name = data["name"] as? String, !name.isEmpty,
                      let phoneNumber = data["phoneNumber"] as? String, !phoneNumber.isEmpty,
                      let age = data["age"] as? Int else {
                    print("❌ Kullanıcı verilerinde eksiklik var")
                    self?.errorMessage = "Kullanıcı verileri eksik"
                    return
                }
                
                let user = User(
                    id: uid,
                    name: name,
                    phoneNumber: phoneNumber,
                    profileImageURL: data["profileImageURL"] as? String ?? "",
                    age: age
                )
                
                self?.currentUser = user
                self?.isLoggedIn = true
                self?.resetAuthState()
                self?.resetAllAttempts()
                
                self?.updateLastLoginTime(uid: uid)
                
                print("✅ Login başarılı: \(user.name)")
            }
        }
    }
    
    
    private func fetchUserData(uid: String) {
        print("📋 Kullanıcı verileri Firestore'dan alınıyor: \(uid)")
        
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Kullanıcı bilgileri alma hatası: \(error.localizedDescription)")
                    self?.errorMessage = "Kullanıcı bilgileri alınamadı: \(error.localizedDescription)"
                    
                   
                    try? Auth.auth().signOut()
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    print("❌ Kullanıcı dokümanı Firestore'da bulunamadı")
                    self?.errorMessage = "Kullanıcı bilgileri bulunamadı"
                    
                    try? Auth.auth().signOut()
                    return
                }
                
                guard let name = data["name"] as? String, !name.isEmpty,
                      let phoneNumber = data["phoneNumber"] as? String, !phoneNumber.isEmpty,
                      let age = data["age"] as? Int else {
                    print("❌ Kullanıcı verilerinde eksiklik var")
                    self?.errorMessage = "Kullanıcı verileri eksik"
                    
                    try? Auth.auth().signOut()
                    return
                }
                
                let user = User(
                    id: uid,
                    name: name,
                    phoneNumber: phoneNumber,
                    profileImageURL: data["profileImageURL"] as? String ?? "",
                    age: age
                )
                
                self?.currentUser = user
                self?.isLoggedIn = true
                self?.resetAuthState()
                self?.resetAllAttempts()
                
                self?.updateLastLoginTime(uid: uid)
                
                print("✅ Kullanıcı giriş başarılı: \(user.name)")
            }
        }
    }
    
    private func updateLastLoginTime(uid: String) {
        db.collection("users").document(uid).updateData([
            "lastLoginAt": Timestamp()
        ]) { error in
            if let error = error {
                print("⚠️ Son giriş zamanı güncellenemedi: \(error.localizedDescription)")
            }
        }
    }
    

    // MARK: - Profile Update Functions

    func updateUserProfile(name: String, age: Int, profileImage: UIImage?) {
        guard let currentUser = currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        guard validateUserProfileInput(name: name, age: age) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        
        let newMockProfileImageURL = generateMockProfileImage()
        updateAuthAndFirestore(
            name: name,
            age: age,
            profileImageURL: newMockProfileImageURL
        )
    }

    private func updateAuthAndFirestore(name: String, age: Int, profileImageURL: String) {
        guard let firebaseUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Firebase kullanıcısı bulunamadı"
            }
            return
        }
        
        // 1. Firebase Auth Profile Update
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = name
        if !profileImageURL.isEmpty {
            changeRequest.photoURL = URL(string: profileImageURL)
        }
        
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Profil güncellenemedi: \(error.localizedDescription)"
                    print("❌ Firebase Auth profile update error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Firebase Auth profil güncellendi")
                
                // 2. Firestore Update
                self?.updateFirestoreProfile(
                    uid: firebaseUser.uid,
                    name: name,
                    age: age,
                    profileImageURL: profileImageURL
                )
            }
        }
    }

    
    private func updateFirestoreProfile(uid: String, name: String, age: Int, profileImageURL: String) {
        let updateData: [String: Any] = [
            "name": name,
            "age": age,
            "profileImageURL": profileImageURL,
            "updatedAt": Timestamp()
        ]
        
        print("💾 Firestore profil güncelleniyor...")
        
        db.collection("users").document(uid).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Profil kaydedilemedi: \(error.localizedDescription)"
                    print("❌ Firestore update error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Firestore profil güncellendi")
                
                // 3. Local User Object Update
                if let currentUser = self?.currentUser {
                    let updatedUser = User(
                        id: currentUser.id,
                        name: name,
                        phoneNumber: currentUser.phoneNumber,
                        profileImageURL: profileImageURL,
                        age: age
                    )
                    
                    self?.currentUser = updatedUser
                    self?.profileUpdateSuccess = true // ✅ Success flag set et
                    print("🎉 Profil güncelleme tamamlandı: \(updatedUser.name)")
                }
            }
        }
    }

    


    func resetProfileUpdateState() {
        profileUpdateSuccess = false
        errorMessage = ""
    }


    private func uploadProfileImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let currentUser = currentUser else {
            completion(nil)
            return
        }
        
        print("📸 Profil resmi upload ediliyor...")
        
        StorageManager.shared.uploadProfileImage(image, userId: currentUser.id) { result in
            switch result {
            case .success(let downloadURL):
                print("✅ Profile image uploaded: \(downloadURL)")
                completion(downloadURL)
                
            case .failure(let error):
                print("❌ Profile image upload failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Fotoğraf yüklenemedi: \(error.localizedDescription)"
                }
                completion(nil)
            }
        }
    }


    func refreshUserData() {
        guard let uid = currentUser?.id else { return }
        fetchUserData(uid: uid)
    }
    
    func signOut() {
        isSigningOut = true
        errorMessage = ""
        
        guard Auth.auth().currentUser != nil else {
            completeSignOut()
            return
        }
        
        do {
            try Auth.auth().signOut()
            print("✅ Firebase çıkış başarılı")
            completeSignOut()
        } catch {
            DispatchQueue.main.async {
                self.isSigningOut = false
                self.errorMessage = "Çıkış yapılamadı: \(error.localizedDescription)"
                print("❌ Çıkış hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func completeSignOut() {
        DispatchQueue.main.async {
            self.isSigningOut = false
            self.isLoggedIn = false
            self.currentUser = nil
            self.clearSessionData()
            self.resetAuthState()
            print("✅ Kullanıcı başarıyla çıkış yaptı")
        }
    }
    
    private func clearSessionData() {
        UserDefaults.standard.removeObject(forKey: "verificationAttempts")
        UserDefaults.standard.removeObject(forKey: "lastVerificationTime")
        UserDefaults.standard.removeObject(forKey: "loginAttempts")
        UserDefaults.standard.removeObject(forKey: "lastLoginAttemptTime")
        
        URLCache.shared.removeAllCachedResponses()
        
        resetAllAttempts()
    }
    
    private func clearAllLocalData() {
        clearSessionData()
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser,
              let currentUserId = currentUser?.id else {
            errorMessage = "Kullanıcı bulunamadı"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🗑️ Hesap silme işlemi başlatılıyor...")
        
        // 1. Önce Firestore'dan kullanıcı verilerini sil
        db.collection("users").document(currentUserId).delete { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Firestore verisi silinemedi: \(error.localizedDescription)"
                    print("❌ Firestore silme hatası: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }
            
            print("✅ Firestore kullanıcı verisi silindi")
            
            // 2. Sonra Firebase Auth'dan hesabı sil
            user.delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Hesap silinemedi: \(error.localizedDescription)"
                        print("❌ Firebase Auth hesap silme hatası: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Firebase Auth hesabı silindi")
                        
                        // 3. Local state'i temizle ve auth sayfasına dön
                        self?.clearAllLocalData()
                        self?.isLoggedIn = false
                        self?.currentUser = nil
                        self?.resetAuthState()
                        
                        print("🎉 Hesap başarıyla silindi, auth sayfasına yönlendiriliyor")
                        completion(true)
                    }
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        var formatted = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        formatted = formatted.replacingOccurrences(of: " ", with: "")
        formatted = formatted.replacingOccurrences(of: "-", with: "")
        formatted = formatted.replacingOccurrences(of: "(", with: "")
        formatted = formatted.replacingOccurrences(of: ")", with: "")
        
        if formatted.hasPrefix("+") {
            return formatted
        }
        
        if formatted.hasPrefix("90") && formatted.count == 12 {
            return "+" + formatted
        }
        
        if formatted.hasPrefix("0") && formatted.count == 11 {
            return "+90" + String(formatted.dropFirst())
        }
        
        if formatted.hasPrefix("5") && formatted.count == 10 {
            return "+90" + formatted
        }
        
        return formatted
    }
    
    private func handleAuthError(_ error: Error) {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.invalidPhoneNumber.rawValue:
            errorMessage = "Geçersiz telefon numarası formatı"
        case AuthErrorCode.quotaExceeded.rawValue:
            errorMessage = "SMS kotası aşıldı, daha sonra tekrar deneyin"
        case AuthErrorCode.invalidVerificationCode.rawValue:
            errorMessage = "Geçersiz doğrulama kodu"
        case AuthErrorCode.sessionExpired.rawValue:
            errorMessage = "Oturum süresi doldu, tekrar deneyin"
        case AuthErrorCode.tooManyRequests.rawValue:
            errorMessage = "Çok fazla istek gönderildi, lütfen bekleyin"
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "İnternet bağlantınızı kontrol edin"
        case AuthErrorCode.missingAppCredential.rawValue:
            errorMessage = "Uygulama yapılandırma hatası"
        case AuthErrorCode.credentialAlreadyInUse.rawValue:
            errorMessage = "Bu telefon numarası zaten kayıtlı"
        default:
            if authError.localizedDescription.contains("network") {
                errorMessage = "İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin."
            } else {
                errorMessage = "Doğrulama işlemi başarısız oldu. Lütfen tekrar deneyin."
            }
        }
        
        print("❌ Authentication hatası: \(errorMessage)")
    }
    
    
    private func startCooldown() {
        cooldownTimeRemaining = cooldownPeriod
        saveLastVerificationTime()
        
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.cooldownTimeRemaining -= 1
            
            if self.cooldownTimeRemaining <= 0 {
                timer.invalidate()
                self.cooldownTimer = nil
            }
        }
    }
    
    private func startLoginCooldown() {
        loginCooldownRemaining = loginCooldownPeriod
        saveLastLoginAttemptTime()
        
        loginCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.loginCooldownRemaining -= 1
            
            if self.loginCooldownRemaining <= 0 {
                timer.invalidate()
                self.loginCooldownTimer = nil
                self.loginAttemptsRemaining = self.maxLoginAttempts
            }
        }
    }
    
    private func decrementVerificationAttempts() {
        remainingAttempts -= 1
        saveVerificationAttempts()
        
        if remainingAttempts <= 0 {
            errorMessage = "Çok fazla yanlış kod girişi. Lütfen yeni kod isteyin."
        }
    }
    
    private func decrementLoginAttempts() {
        loginAttemptsRemaining -= 1
        saveLoginAttempts()
        
        if loginAttemptsRemaining <= 0 {
            startLoginCooldown()
        }
    }
    
    private func resetVerificationAttempts() {
        remainingAttempts = maxVerificationAttempts
        saveVerificationAttempts()
    }
    
    private func resetAllAttempts() {
        remainingAttempts = maxVerificationAttempts
        loginAttemptsRemaining = maxLoginAttempts
        cooldownTimeRemaining = 0
        loginCooldownRemaining = 0
        
        saveVerificationAttempts()
        saveLoginAttempts()
        
        cooldownTimer?.invalidate()
        loginCooldownTimer?.invalidate()
    }
    
    // MARK: - UserDefaults İşlemleri
    
    private func saveVerificationAttempts() {
        UserDefaults.standard.set(remainingAttempts, forKey: "verificationAttempts")
    }
    
    private func saveLoginAttempts() {
        UserDefaults.standard.set(loginAttemptsRemaining, forKey: "loginAttempts")
    }
    
    private func saveLastVerificationTime() {
        UserDefaults.standard.set(Date(), forKey: "lastVerificationTime")
    }
    
    private func saveLastLoginAttemptTime() {
        UserDefaults.standard.set(Date(), forKey: "lastLoginAttemptTime")
    }
    
    private func loadPersistedAttempts() {
        remainingAttempts = UserDefaults.standard.object(forKey: "verificationAttempts") as? Int ?? maxVerificationAttempts
        loginAttemptsRemaining = UserDefaults.standard.object(forKey: "loginAttempts") as? Int ?? maxLoginAttempts
        
        if let lastVerificationTime = UserDefaults.standard.object(forKey: "lastVerificationTime") as? Date {
            let elapsed = Date().timeIntervalSince(lastVerificationTime)
            if elapsed < cooldownPeriod {
                cooldownTimeRemaining = cooldownPeriod - elapsed
                startCooldown()
            }
        }
        
        if let lastLoginAttemptTime = UserDefaults.standard.object(forKey: "lastLoginAttemptTime") as? Date {
            let elapsed = Date().timeIntervalSince(lastLoginAttemptTime)
            if elapsed < loginCooldownPeriod && loginAttemptsRemaining <= 0 {
                loginCooldownRemaining = loginCooldownPeriod - elapsed
                startLoginCooldown()
            }
        }
    }
    
    func resetAuthState() {
        isCodeSent = false
        verificationID = nil
        errorMessage = ""
    }
    
    func resendVerificationCode(phoneNumber: String) {
        sendVerificationCode(phoneNumber: phoneNumber)
    }
}
