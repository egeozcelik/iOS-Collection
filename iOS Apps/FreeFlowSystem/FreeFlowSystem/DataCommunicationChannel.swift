//
//  DataCommunicationChannel.swift
//  FreeFlowSystem
//
//  Created by Ege on 17.03.2025.
//

//MARK: BLE session here on this script
import Foundation
import CoreBluetooth
import os

struct TransferService {
    static let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
}

enum BluetoothLECentralError: Error {
    case noPeripheral
    case scanning
    case notReady
}

class DataCommunicationChannel: NSObject {
    var centralManager: CBCentralManager!
    
    var discoveredPeripheral: CBPeripheral?
    var discoveredPeripheralName: String?
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0

    let defaultIterations = 5
    
    var accessoryDataHandler: ((Data, String) -> Void)?
    var accessoryConnectedHandler: ((String) -> Void)?
    var accessoryDisconnectedHandler: (() -> Void)?
    var rssiUpdateHandler: ((Int) -> Void)?
    
    var bluetoothReady = false
    var shouldStartWhenReady = false
    var isScanning = false

    let logger = os.Logger(subsystem: "com.example.UWBTurnike", category: "DataChannel")
    var ctr = true //Ege Edit
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    deinit {
        centralManager.stopScan()
        logger.info("Scanning stopped")
    }
    
    func sendData(_ data: Data) throws {
        if discoveredPeripheral == nil {
            throw BluetoothLECentralError.noPeripheral
        }
        writeData(data)
    }
    
    func start() {
        if bluetoothReady {
            retrievePeripheral()
        } else {
            shouldStartWhenReady = true
        }
    }
    // edit eö.
    func startScan() throws { //Start scanning manually here
        if !bluetoothReady {
            throw BluetoothLECentralError.notReady
        }
        
        if isScanning {
            throw BluetoothLECentralError.scanning
        }
        
        isScanning = true
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID],
                                         options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        logger.info("Manuel BLE taraması başlatıldı")
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
        logger.info("BLE taraması durduruldu")
    }
    
    func disconnect() {
        if let peripheral = discoveredPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            logger.info("Aksesuar bağlantısı manuel olarak kesildi")
        }
    }

    private func retrievePeripheral() {
        let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID]))

        logger.info("Found connected Peripherals with transfer service: \(connectedPeripherals)")

        if let connectedPeripheral = connectedPeripherals.last {
            logger.info("Connecting to peripheral \(connectedPeripheral)")
            self.discoveredPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
        } else {
            logger.info("Not connected, starting to scan.")
            
            isScanning = true
            centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    private func cleanup() {
        // Don't do anything if we're not connected
        guard let discoveredPeripheral = discoveredPeripheral,
              case .connected = discoveredPeripheral.state else { return }

        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.rxCharacteristicUUID && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }

        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    private func writeData(_ data: Data) {
        guard let discoveredPeripheral = discoveredPeripheral,
              let transferCharacteristic = rxCharacteristic
        else { return }
        let mtu = discoveredPeripheral.maximumWriteValueLength(for: .withResponse)

        let bytesToCopy: size_t = min(mtu, data.count)

        var rawPacket = [UInt8](repeating: 0, count: bytesToCopy)
        data.copyBytes(to: &rawPacket, count: bytesToCopy)
        let packetData = Data(bytes: &rawPacket, count: bytesToCopy)

        let stringFromData = packetData.map { String(format: "0x%02x, ", $0) }.joined()
        logger.info("Writing \(bytesToCopy) bytes: \(String(describing: stringFromData))")

        discoveredPeripheral.writeValue(packetData, for: transferCharacteristic, type: .withResponse)
        
        writeIterationsComplete += 1
    }
    
    func share_unique_id() -> Bool {
        guard let discoveredPeripheral = discoveredPeripheral,
              let transferCharacteristic = rxCharacteristic
        else { return false }
        
        if let dataToSend = "KK_UNIQUE_ID".data(using: .utf8) {
            discoveredPeripheral.writeValue(dataToSend, for: transferCharacteristic, type: .withResponse)
            print("unique data sended..")
            return true
        } else {
            return false
        }
    }
    
    func readRSSI() {
        discoveredPeripheral?.readRSSI()
        /**
         *  @method discoverServices:
         *
         *  @param serviceUUIDs A list of <code>CBUUID</code> objects representing the service types to be discovered. If <i>nil</i>,
         *                        all services will be discovered.
         *
         *  @discussion            Discovers available service(s) on the peripheral.
         *
         *  @see                peripheral:didDiscoverServices:
         */
    }
}

extension DataCommunicationChannel: CBCentralManagerDelegate {
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("CBManager is powered on")
            bluetoothReady = true
            if shouldStartWhenReady {
                start()
            }
        // In your app, deal with the following states as necessary.
        case .poweredOff:
            logger.error("CBManager is not powered on")
            bluetoothReady = false
            return
        case .resetting:
            logger.error("CBManager is resetting")
            bluetoothReady = false
            return
        case .unauthorized:
            handleCBUnauthorized()
            bluetoothReady = false
            return
        case .unknown:
            logger.error("CBManager state is unknown")
            bluetoothReady = false
            return
        case .unsupported:
            logger.error("Bluetooth is not supported on this device")
            bluetoothReady = false
            return
        @unknown default:
            logger.error("A previously unknown central manager state occurred")
            bluetoothReady = false
            return
        }
    }

    internal func handleCBUnauthorized() {
        switch CBManager.authorization {
        case .denied:
            logger.error("The user denied Bluetooth access.")
        case .restricted:
            logger.error("Bluetooth is restricted")
        default:
            logger.error("Unexpected authorization")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        logger.info("Discovered \(String(describing: peripheral.name)) at \(RSSI.intValue)")
        
        rssiUpdateHandler?(RSSI.intValue)
        
        if discoveredPeripheral != peripheral {
            
            discoveredPeripheral = peripheral
            
            logger.info("Connecting to perhiperal \(peripheral)")
            
            let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unknown"
            discoveredPeripheralName = name
            centralManager.connect(peripheral, options: nil)
        }
    }

    // Reacts to connection failure.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to \(peripheral). \(String(describing: error))")
        cleanup()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let didConnectHandler = accessoryConnectedHandler {
            let name = discoveredPeripheralName ?? "Bilinmeyen Cihaz"
            didConnectHandler(name)
        }
        
        logger.info("Peripheral Connected")
        
        centralManager.stopScan()
        isScanning = false
        logger.info("Scanning stopped")
        
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        
        peripheral.delegate = self
        
        peripheral.discoverServices([TransferService.serviceUUID])
        
        peripheral.readRSSI()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("Perhiperal Disconnected")
        discoveredPeripheral = nil
        discoveredPeripheralName = nil
        
        if let didDisconnectHandler = accessoryDisconnectedHandler {
            didDisconnectHandler()
        }
        
        if connectionIterationsComplete < defaultIterations {
            retrievePeripheral()
        } else {
            logger.info("Connection iterations completed")
        }
    }
}

extension DataCommunicationChannel: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            logger.error("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        logger.info("discovered service. Now discovering characteristics")
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.rxCharacteristicUUID, TransferService.txCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.error("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        }

            guard let serviceCharacteristics = service.characteristics else { return }
            for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.rxCharacteristicUUID {
                // Subscribe to the transfer service's `rxCharacteristic`.
                rxCharacteristic = characteristic
                logger.info("discovered characteristic: \(characteristic)")
                peripheral.setNotifyValue(true, for: characteristic)
            }

            for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.txCharacteristicUUID {
                // Subscribe to the transfer service's `txCharacteristic`.
                txCharacteristic = characteristic
                logger.info("discovered characteristic: \(characteristic)")
                peripheral.setNotifyValue(true, for: characteristic)
            }

            // Wait for the peripheral to send data. (if any)
        
            // Will be added soon
        }

            func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
                if let error = error {
                    logger.error("Error discovering characteristics:\(error.localizedDescription)")
                    cleanup()
                    return
                }
                guard let characteristicData = characteristic.value else { return }
            
                let str = characteristicData.map { String(format: "0x%02x, ", $0) }.joined()
                logger.info("Received \(characteristicData.count) bytes: \(str)")
                
                if let dataHandler = self.accessoryDataHandler, let accessoryName = discoveredPeripheralName {
                    dataHandler(characteristicData, accessoryName)
                }
            }

            func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
                if let error = error {
                    logger.error("Error changing notification state: \(error.localizedDescription)")
                    return
                }

                if characteristic.isNotifying {
                    logger.info("Notification began on \(characteristic)")
                } else {
                    logger.info("Notification stopped on \(characteristic). Disconnecting")
                    cleanup()
                }
            }
            
            func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
                if let error = error {
                    logger.error("RSSI okuma hatası: \(error.localizedDescription)")
                    return
                }
                
                rssiUpdateHandler?(RSSI.intValue)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    if peripheral.state == .connected {
                        peripheral.readRSSI()
                    }
                }
            }
        }
