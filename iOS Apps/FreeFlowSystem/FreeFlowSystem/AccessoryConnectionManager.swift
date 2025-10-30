//
//  AccessoryConnectionManager.swift
//  FreeFlowSystem
//
//  Created by Ege on 17.03.2025.
//

//MARK: UWB SESSION HANDLING HERE ON THIS SCRIPT
 
import Foundation
import NearbyInteraction
import SwiftUI

// MARK: - Messages, towards to anchor
enum MessageId: UInt8 {
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
}

class AccessoryConnectionManager: NSObject, ObservableObject {
    var niSession = NISession()
    var configuration: NINearbyAccessoryConfiguration?
    var accessoryMap = [NIDiscoveryToken: String]()
    
    var dataChannel = DataCommunicationChannel()
    
    @Published var accessoryConnected = false
    @Published var connectedAccessoryName: String?
    @Published var uwbActive = false
    @Published var distance: Double?
    @Published var statusMessage = "Aksesuarlar aranıyor..."
    @Published var sessionInfo = UWBSessionInfo()
    @Published var rssiValue: Int?
    
    override init() {
        super.init()
        setupSession()
        setupDataChannel()
    }
    
    private func setupSession() {
        niSession.delegate = self
        LogManager.shared.log(.system, message: "NISession oluşturuldu")
    }
    
    private func setupDataChannel() {
        dataChannel.accessoryConnectedHandler = { [weak self] name in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.accessoryConnected = true
                self.connectedAccessoryName = name
                self.statusMessage = "'\(name)' ile bağlantı kuruldu."
            }
            LogManager.shared.log(.ble, message: "Aksesuar bağlandı", details: "Cihaz: \(name)")
        }
        
        dataChannel.accessoryDisconnectedHandler = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.accessoryConnected = false
                self.connectedAccessoryName = nil
                self.statusMessage = "Aksesuar bağlantısı kesildi."
                self.uwbActive = false
                self.sessionInfo.updateStatus(.stopped)
            }
            LogManager.shared.log(.ble, message: "Aksesuar bağlantısı kesildi")
        }
        
        dataChannel.accessoryDataHandler = { [weak self] data, accessoryName in
            self?.handleAccessoryData(data, accessoryName: accessoryName)
            LogManager.shared.log(.ble, message: "Aksesuardan veri alındı",
                                  details: "Boyut: \(data.count) bytes, Cihaz: \(accessoryName)")
        }
        
        dataChannel.rssiUpdateHandler = { [weak self] rssi in
            DispatchQueue.main.async {
                self?.rssiValue = rssi
            }
        }
        
        dataChannel.start()
        LogManager.shared.log(.system, message: "DataCommunicationChannel başlatıldı")
    }
    
    func resetUWBSession() {
        LogManager.shared.log(.uwb, message: "UWB oturumu sıfırlanıyor")
        updateStatusMessage(with: "UWB Oturumu yeniden başlatılıyor...")
        sessionInfo.updateStatus(.stopped)
        
        sendDataToAccessory(Data([MessageId.stop.rawValue]))
        
        // Oturum sıfırlama
        niSession.invalidate()
        niSession = NISession()
        niSession.delegate = self
        sessionInfo.reset()
        
        DispatchQueue.main.async {
            self.uwbActive = false
        }
        
        LogManager.shared.log(.system, message: "NISession yeniden oluşturuldu")
    }
    
    func initialize() {
        updateStatusMessage(with: "Aksesuarın yapılandırma verisi talep ediliyor...")
        LogManager.shared.log(.uwb, message: "UWB başlatma isteği gönderiliyor")
        sessionInfo.updateStatus(.starting)
        
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg)
    }
    
    func handleAccessoryData(_ data: Data, accessoryName: String) {
        if data.count < 1 {
            updateStatusMessage(with: "Aksesuar tarafından paylaşılan veri boyutu 1'den az.")
            LogManager.shared.log(.error, message: "Geçersiz veri boyutu", details: "Boyut: \(data.count)")
            return
        }
        
        guard let messageId = MessageId(rawValue: data.first!) else {
            LogManager.shared.log(.error, message: "Geçersiz mesaj ID", details: "ID: \(data.first!)")
            fatalError("\(data.first!) geçerli bir MessageId değil.")
        }
        
        switch messageId {
        case .accessoryConfigurationData: //01
            assert(data.count > 1)
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName)
            LogManager.shared.log(.uwb, message: "Yapılandırma verisi alındı", details: "Boyut: \(message.count) bytes")
        case .accessoryUwbDidStart: //02
            handleAccessoryUwbDidStart()
            LogManager.shared.log(.uwb, message: "UWB başlatıldı")
        case .accessoryUwbDidStop: // 03
            handleAccessoryUwbDidStop()
            LogManager.shared.log(.uwb, message: "UWB durduruldu")
        case .configureAndStart, .initialize, .stop:  // 0B, 0A, 0C
            LogManager.shared.log(.error, message: "Beklenmeyen mesaj tipi alındı", details: "Tip: \(messageId)")
            fatalError("Aksesuar bu mesajları göndermemelidir.")
        }
    }
    
    func setupAccessory(_ configData: Data, name: String) {
        updateStatusMessage(with: "'\(name)' ile yapılandırma verisi alındı. Oturum çalıştırılıyor...")
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            LogManager.shared.log(.uwb, message: "NINearbyAccessoryConfiguration oluşturuldu")
        } catch {
            updateStatusMessage(with: "'\(name)' için NINearbyAccessoryConfiguration oluşturulamadı. Hata: \(error)")
            LogManager.shared.log(.error, message: "NINearbyAccessoryConfiguration oluşturma hatası",
                                  details: error.localizedDescription)
            sessionInfo.updateStatus(.error)
            return
        }
        
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)
        
        if dataChannel.share_unique_id() {
            niSession.run(configuration!)
            LogManager.shared.log(.uwb, message: "Yetkilendirme başarılı, NISession başlatıldı")
            print("authorization successful")
        } else {
            LogManager.shared.log(.error, message: "Unique ID paylaşımı başarısız")
            sessionInfo.updateStatus(.error)
        }
    }
    
    func handleAccessoryUwbDidStart() {
        updateStatusMessage(with: "Aksesuar oturumu başlatıldı.")
        DispatchQueue.main.async {
            self.uwbActive = true
            self.sessionInfo.updateStatus(.active)
        }
    }
    
    func handleAccessoryUwbDidStop() {
        updateStatusMessage(with: "Aksesuar oturumu durduruldu.")
        DispatchQueue.main.async {
            self.uwbActive = false
            self.sessionInfo.updateStatus(.stopped)
        }
    }
    
    func sendDataToAccessory(_ data: Data) {
        do {
            // MARK: on Firmware (KKLib directory), HE for mapping to authenticate
            let combinedData = data + "HE".data(using: .utf8)! // Ege Edit
            try dataChannel.sendData(combinedData)
            LogManager.shared.log(.ble, message: "Aksesuara veri gönderildi",
                                  details: "Boyut: \(combinedData.count) bytes")
        } catch {
            updateStatusMessage(with: "Aksesuar'a veri gönderme başarısız oldu: \(error)")
            LogManager.shared.log(.error, message: "Veri gönderme hatası",
                                  details: error.localizedDescription)
        }
    }
    
    func updateStatusMessage(with text: String) {
        LogManager.shared.log(.system, message: "Durum güncellendi", details: text)
        DispatchQueue.main.async {
            self.statusMessage = text
        }
    }
    
    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }
    
    func handleSessionInvalidation() {
        updateStatusMessage(with: "Oturum geçersiz. Yeniden başlatılıyor.")
        LogManager.shared.log(.uwb, message: "Oturum geçersizleştirildi, yeniden başlatılıyor")
        sessionInfo.updateStatus(.error)
        
        sendDataToAccessory(Data([MessageId.stop.rawValue]))
        
        niSession = NISession()
        niSession.delegate = self
        LogManager.shared.log(.system, message: "NISession yeniden oluşturuldu")
        
        sendDataToAccessory(Data([MessageId.initialize.rawValue]))
    }
    
    func handleUserDidNotAllow() {
        updateStatusMessage(with: "Nearby Interactions erişimi gereklidir. Ayarlardan NIAccessory için erişimi değiştirebilirsiniz.")
        LogManager.shared.log(.error, message: "Kullanıcı NI erişimine izin vermedi")
        sessionInfo.updateStatus(.error)
    }
}

// MARK: - NISessionDelegate
extension AccessoryConnectionManager: NISessionDelegate {
    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }
        
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        
        let accessoryName = accessoryMap[object.discoveryToken] ?? "Bilinmiyor"
        
        sendDataToAccessory(msg)
        updateStatusMessage(with: "'\(accessoryName)' ile paylaşılabilir yapılandırma verisi gönderildi.")
        LogManager.shared.log(.uwb, message: "Paylaşılabilir yapılandırma verisi gönderildi",
                              details: "Boyut: \(shareableConfigurationData.count) bytes")
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        guard let distance = accessory.distance else { return }
        guard let name = accessoryMap[accessory.discoveryToken] else { return }

        DispatchQueue.main.async {
            self.distance = Double(distance)
            self.sessionInfo.incrementPacketCount()
        }
        
        if self.sessionInfo.packetCount % 20 == 0 { // Her 20 pakette bir loglama
            LogManager.shared.log(.uwb, message: "Mesafe güncellendi",
                                 details: "Cihaz: \(name), Mesafe: \(String(format: "%.2f", distance))m")
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard reason == .timeout else { return }
        updateStatusMessage(with: "'\(self.connectedAccessoryName ?? "aksesuar")' ile oturum zaman aşımına uğradı.")
        LogManager.shared.log(.uwb, message: "Oturum zaman aşımı")
        sessionInfo.updateStatus(.error)
        
        guard let accessory = nearbyObjects.first else { return }
        accessoryMap.removeValue(forKey: accessory.discoveryToken)
        
        if accessoryConnected {
            sendDataToAccessory(Data([MessageId.stop.rawValue]))
            sendDataToAccessory(Data([MessageId.initialize.rawValue]))
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        updateStatusMessage(with: "Oturum askıya alındı.")
        LogManager.shared.log(.uwb, message: "Oturum askıya alındı")
        sessionInfo.updateStatus(.paused)
        
        let msg = Data([MessageId.stop.rawValue])
        sendDataToAccessory(msg)
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        updateStatusMessage(with: "Oturum askıya alma süresi sona erdi.")
        LogManager.shared.log(.uwb, message: "Oturum askıya alma süresi sona erdi")
        
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg)
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        LogManager.shared.log(.error, message: "Oturum geçersizleştirildi",
                             details: error.localizedDescription)
        
        switch error {
        case NIError.invalidConfiguration:
            updateStatusMessage(with: "Aksesuar yapılandırma verisi geçersiz. Lütfen bunu hata ayıklayın ve tekrar deneyin.")
            sessionInfo.updateStatus(.error)
        case NIError.userDidNotAllow:
            handleUserDidNotAllow()
        default:
            handleSessionInvalidation()
        }
    }
}
