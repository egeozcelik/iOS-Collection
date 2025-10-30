//
//  WatchConnectionManager.swift
//  FreeFlowSystem
//
//  Created by Ege on 14.05.2025.
//

import Foundation
import NearbyInteraction
import CoreBluetooth
import os.log

// MARK: - Messages
enum MessageId: UInt8 {
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
}

class WatchConnectionManager: NSObject, ObservableObject {
    // UWB özellikleri
    var niSession = NISession()
    var configuration: NINearbyAccessoryConfiguration?
    var accessoryMap = [NIDiscoveryToken: String]()
    
    // Bluetooth özellikleri
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var discoveredPeripheralName: String?
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    
    // UI için yayınlanan değişkenler
    @Published var accessoryConnected = false
    @Published var connectedAccessoryName: String?
    @Published var uwbActive = false
    @Published var distance: Double?
    @Published var statusMessage = "Aksesuarlar aranıyor..."
    @Published var rssiValue: Int?
    
    private let logger = os.Logger(subsystem: "com.example.FreeFlowWatch", category: "WatchConnectionManager")
    
    // BLE hizmet ve karakteristik UUID'leri
    let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override init() {
        super.init()
        setupSession()
        setupBluetooth()
    }
    
    // MARK: - Setup Methods
    
    private func setupSession() {
        niSession.delegate = self
        logger.info("NISession oluşturuldu")
    }
    
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        logger.info("Bluetooth yöneticisi oluşturuldu")
    }
    
    // MARK: - Public Methods
    
    func startScan() {
        // Bluetooth taramasını başlat
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID],
                                             options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            statusMessage = "Bluetooth taraması başladı..."
            logger.info("BLE taraması başlatıldı")
        } else {
            statusMessage = "Bluetooth hazır değil!"
            logger.error("Bluetooth hazır değil, tarama başlatılamadı")
        }
    }
    
    func initialize() {
        statusMessage = "UWB başlatılıyor..."
        logger.info("UWB başlatma isteği gönderiliyor")
        
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg)
    }
    
    func sendStopMessage() {
        statusMessage = "UWB durduruluyor..."
        logger.info("UWB durdurma isteği gönderiliyor")
        
        let msg = Data([MessageId.stop.rawValue])
        sendDataToAccessory(msg)
    }
    
    // MARK: - Private Methods
    
    private func sendDataToAccessory(_ data: Data) {
        guard let peripheral = discoveredPeripheral,
              let characteristic = rxCharacteristic else {
            statusMessage = "Aksesuar bağlı değil"
            return
        }
        
        // "HE" kimlik bilgisini ekle
        let combinedData = data + "HE".data(using: .utf8)!
        peripheral.writeValue(combinedData, for: characteristic, type: .withResponse)
        logger.info("Aksesuara veri gönderildi: \(data.count) bytes")
    }
    
    private func handleAccessoryData(_ data: Data, accessoryName: String) {
        if data.count < 1 {
            statusMessage = "Geçersiz veri boyutu"
            logger.error("Geçersiz veri boyutu: \(data.count)")
            return
        }
        
        guard let messageId = MessageId(rawValue: data.first!) else {
            logger.error("Geçersiz mesaj ID: \(data.first!)")
            return
        }
        
        switch messageId {
        case .accessoryConfigurationData: // 01
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName)
            logger.info("Yapılandırma verisi alındı: \(message.count) bytes")
            
        case .accessoryUwbDidStart: // 02
            statusMessage = "UWB başlatıldı"
            uwbActive = true
            logger.info("UWB başlatıldı")
            
        case .accessoryUwbDidStop: // 03
            statusMessage = "UWB durduruldu"
            uwbActive = false
            logger.info("UWB durduruldu")
            
        case .initialize, .configureAndStart, .stop:
            logger.error("Beklenmeyen mesaj tipi: \(messageId.rawValue)")
        }
    }
    
    private func setupAccessory(_ configData: Data, name: String) {
        statusMessage = "Yapılandırma verisi alındı. Oturum başlatılıyor..."
        
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            logger.info("NINearbyAccessoryConfiguration oluşturuldu")
        } catch {
            statusMessage = "Yapılandırma oluşturulamadı: \(error.localizedDescription)"
            logger.error("Yapılandırma hatası: \(error.localizedDescription)")
            return
        }
        
        // Token'ı önbelleğe al
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)
        
        // Unique ID gönder ve oturumu başlat
        if sendUniqueID() {
            niSession.run(configuration!)
            logger.info("NISession başlatıldı")
        } else {
            statusMessage = "Unique ID gönderilemedi"
            logger.error("Unique ID gönderilemedi")
        }
    }
    
    private func sendUniqueID() -> Bool {
        guard let peripheral = discoveredPeripheral,
              let characteristic = rxCharacteristic else {
            return false
        }
        
        if let dataToSend = "KK_UNIQUE_ID".data(using: .utf8) {
            peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
            logger.info("Unique ID gönderildi")
            return true
        }
        return false
    }
    
    private func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }
}

// MARK: - NISessionDelegate
extension WatchConnectionManager: NISessionDelegate {
    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }
        
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        
        sendDataToAccessory(msg)
        statusMessage = "Yapılandırma verisi gönderildi"
        logger.info("Paylaşılabilir yapılandırma verisi gönderildi")
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        guard let distance = accessory.distance else { return }
        
        DispatchQueue.main.async {
            self.distance = Double(distance)
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        if reason == .timeout {
            statusMessage = "UWB oturumu zaman aşımı"
            logger.info("Oturum zaman aşımı")
            
            if accessoryConnected {
                sendStopMessage()
                initialize()
            }
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        statusMessage = "Oturum askıya alındı"
        logger.info("Oturum askıya alındı")
        sendStopMessage()
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        statusMessage = "Oturum devam ediyor"
        logger.info("Oturum askıya alma sona erdi")
        initialize()
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        statusMessage = "Oturum geçersiz: \(error.localizedDescription)"
        logger.error("Oturum geçersizleştirildi: \(error.localizedDescription)")
        
        niSession = NISession()
        niSession.delegate = self
    }
}

// MARK: - CBCentralManagerDelegate
extension WatchConnectionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("Bluetooth açık")
            startScan() // Bluetooth hazır olduğunda taramayı başlat
        case .poweredOff:
            statusMessage = "Bluetooth kapalı"
            logger.error("Bluetooth kapalı")
        case .unauthorized:
            statusMessage = "Bluetooth yetkisi yok"
            logger.error("Bluetooth yetkisi yok")
        case .unsupported:
            statusMessage = "Bluetooth desteklenmiyor"
            logger.error("Bluetooth desteklenmiyor")
        default:
            statusMessage = "Bluetooth hazır değil"
            logger.error("Bluetooth durumu: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        logger.info("Cihaz bulundu: \(peripheral.name ?? "İsimsiz")")
        rssiValue = RSSI.intValue
        
        if discoveredPeripheral != peripheral {
            // Yeni bir çevresel cihaz keşfedildi
            discoveredPeripheral = peripheral
            let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Bilinmeyen"
            discoveredPeripheralName = name
            
            statusMessage = "Bağlanılıyor: \(name)"
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Bağlantı kuruldu")
        
        // Taramayı durdur
        centralManager.stopScan()
        
        // Bağlantı durumunu güncelle
        DispatchQueue.main.async {
            self.accessoryConnected = true
            self.connectedAccessoryName = self.discoveredPeripheralName
            self.statusMessage = "Bağlandı: \(self.discoveredPeripheralName ?? "Cihaz")"
        }
        
        // Servis taramasını başlat
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("Bağlantı kesildi")
        
        // Bağlantı durumunu güncelle
        DispatchQueue.main.async {
            self.accessoryConnected = false
            self.connectedAccessoryName = nil
            self.uwbActive = false
            self.statusMessage = "Bağlantı kesildi"
            self.distance = nil
        }
        
        startScan()
    }
}

// MARK: - CBPeripheralDelegate
extension WatchConnectionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            statusMessage = "Servis hatası: \(error.localizedDescription)"
            logger.error("Servis keşif hatası: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            logger.info("Servis bulundu: \(service.uuid)")
            peripheral.discoverCharacteristics([rxCharacteristicUUID, txCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            statusMessage = "Karakteristik hatası: \(error.localizedDescription)"
            logger.error("Karakteristik keşif hatası: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == rxCharacteristicUUID {
                rxCharacteristic = characteristic
                logger.info("RX karakteristiği bulundu")
            }
            
            if characteristic.uuid == txCharacteristicUUID {
                txCharacteristic = characteristic
                logger.info("TX karakteristiği bulundu")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Değer güncelleme hatası: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            return
        }
        
        if characteristic.uuid == txCharacteristicUUID {
            handleAccessoryData(data, accessoryName: discoveredPeripheralName ?? "Bilinmeyen")
        }
    }
}
