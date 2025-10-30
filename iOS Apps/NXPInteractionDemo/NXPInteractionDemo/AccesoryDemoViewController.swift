import UIKit
import NearbyInteraction
enum MessageId: UInt8 {
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
}

class AccessoryDemoViewController: UIViewController {
    var dataChannel = DataCommunicationChannel()
    var niSession = NISession()
    var configuration: NINearbyAccessoryConfiguration?
    var accessoryConnected = false
    var connectedAccessoryName: String?
    var accessoryMap = [NIDiscoveryToken: String]()

    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var uwbStateLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var direction: UILabel!
    @IBOutlet weak var verticalDirectionEstimatelbl: UILabel!
    @IBOutlet weak var horizontalAnglelbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        niSession.delegate = self
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()
        
        updateInfoLabel(with: "Aksesuarlar aranıyor...")
        
        
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        updateInfoLabel(with: "Aksesuarın yapılandırma verisi talep ediliyor...")
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg)
    }
    
    func accessorySharedData(data: Data, accessoryName: String) {
        if data.count < 1 {
            updateInfoLabel(with: "Aksesuar tarafından paylaşılan veri boyutu 1'den az.")
            return
        }
        
        guard let messageId = MessageId(rawValue: data.first!) else {
            fatalError("\(data.first!) geçerli bir MessageId değil.")
        }
        
        switch messageId {
        case .accessoryConfigurationData:
            assert(data.count > 1)
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName)
        case .accessoryUwbDidStart:
            handleAccessoryUwbDidStart()
        case .accessoryUwbDidStop:
            handleAccessoryUwbDidStop()
        case .configureAndStart, .initialize, .stop:
            fatalError("Aksesuar bu mesajları göndermemelidir.")
        }
    }
    
    func accessoryConnected(name: String) {
        accessoryConnected = true
        connectedAccessoryName = name
        actionButton.isEnabled = true
        connectionStateLabel.text = "Bağlandı"
        updateInfoLabel(with: "'\(name)' ile bağlantı kuruldu.")
        
    }
    
    func accessoryDisconnected() {
        accessoryConnected = false
        actionButton.isEnabled = false
        connectedAccessoryName = nil
        connectionStateLabel.text = "Bağlantı Kesildi"
        updateInfoLabel(with: "Aksesuar bağlantısı kesildi.")
    }
    
    func setupAccessory(_ configData: Data, name: String) {
        updateInfoLabel(with: "'\(name)' ile yapılandırma verisi alındı. Oturum çalıştırılıyor...")
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
        } catch {
            updateInfoLabel(with: "'\(name)' için NINearbyAccessoryConfiguration oluşturulamadı. Hata: \(error)")
            return
        }
        
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)
        //niSession.run(configuration!)
        
        
        //Ege Edit
        if dataChannel.share_unique_id(){
            
            niSession.run(configuration!)
            print("authorization successful")
        }
        else{
            
        }
    }
    
    func handleAccessoryUwbDidStart() {
        updateInfoLabel(with: "Aksesuar oturumu başlatıldı.")
        actionButton.isEnabled = false
        self.uwbStateLabel.text = "AÇIK"
    }
    
    func handleAccessoryUwbDidStop() {
        updateInfoLabel(with: "Aksesuar oturumu durduruldu.")
        if accessoryConnected {
            actionButton.isEnabled = true
        }
        self.uwbStateLabel.text = "KAPALI"
    }
}

// MARK: - `NISessionDelegate`.

extension AccessoryDemoViewController: NISessionDelegate {
    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }
        
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        
        let accessoryName = accessoryMap[object.discoveryToken] ?? "Bilinmiyor"
        
        sendDataToAccessory(msg)
        updateInfoLabel(with: "'\(accessoryName)' ile paylaşılabilir yapılandırma verisi gönderildi.")
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        
        guard let distance = accessory.distance else { return }
        guard let name = accessoryMap[accessory.discoveryToken] else { return }

        self.distanceLabel.text = String(format: "'%@' ile mesafe: %0.1fm ", name, distance)
        self.distanceLabel.sizeToFit()
        
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard reason == .timeout else { return }
        updateInfoLabel(with: "'\(self.connectedAccessoryName ?? "aksesuar")' ile oturum zaman aşımına uğradı.")
        
        guard let accessory = nearbyObjects.first else { return }
        accessoryMap.removeValue(forKey: accessory.discoveryToken)
        
        if shouldRetry(accessory) {
            sendDataToAccessory(Data([MessageId.stop.rawValue]))
            sendDataToAccessory(Data([MessageId.initialize.rawValue]))
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        updateInfoLabel(with: "Oturum askıya alındı.")
        let msg = Data([MessageId.stop.rawValue])
        sendDataToAccessory(msg)
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        updateInfoLabel(with: "Oturum askıya alma süresi sona erdi.")
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg)
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        switch error {
        case NIError.invalidConfiguration:
            updateInfoLabel(with: "Aksesuar yapılandırma verisi geçersiz. Lütfen bunu hata ayıklayın ve tekrar deneyin.")
        case NIError.userDidNotAllow:
            handleUserDidNotAllow()
        default:
            handleSessionInvalidation()
        }
    }
}

// MARK: - Yardımcılar.

extension AccessoryDemoViewController {
    func updateInfoLabel(with text: String) {
        self.infoLabel.text = text
        self.distanceLabel.sizeToFit()
    }
    
    func sendDataToAccessory(_ data: Data) {
        do {
            //try dataChannel.sendData(data)
            let combinedData = data + "HE".data(using: .utf8)! //Ege Edit
            
            try dataChannel.sendData(combinedData)
        } catch {
            updateInfoLabel(with: "Aksesuar'a veri gönderme başarısız oldu: \(error)")
        }
    }
    
    func handleSessionInvalidation() {
        updateInfoLabel(with: "Oturum geçersiz. Yeniden başlatılıyor.")
        sendDataToAccessory(Data([MessageId.stop.rawValue]))
        
        
        

        self.niSession = NISession()
        self.niSession.delegate = self

        sendDataToAccessory(Data([MessageId.initialize.rawValue]))
    }
    
    func shouldRetry(_ accessory: NINearbyObject) -> Bool {
        return accessoryConnected
    }
    
    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }
    
    func handleUserDidNotAllow() {
        updateInfoLabel(with: "Nearby Interactions erişimi gereklidir. Ayarlardan NIAccessory için erişimi değiştirebilirsiniz.")
        
        let accessAlert = UIAlertController(title: "Erişim Gerekli",
                                            message: """
                                            NIAccessory, bu örnek uygulama için Nearby Interactions'a erişim gerektirir.
                                            """,
                                            preferredStyle: .alert)
        accessAlert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        accessAlert.addAction(UIAlertAction(title: "Ayarlar'a Git", style: .default, handler: {_ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))

        present(accessAlert, animated: true, completion: nil)
    }
}
