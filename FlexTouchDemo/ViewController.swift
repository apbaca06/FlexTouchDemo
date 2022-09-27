//
//  ViewController.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/16.
//

import UIKit
import CoreBluetooth
import Combine
import CommonCrypto
import CryptoKit

class ViewController: UIViewController {
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    @Published var bluetoothState: CBManagerState = .unknown
    var bag = Set<AnyCancellable>()
    @Published var peripheralInfo: MallyaPeripheralInfo? = nil
    private(set) var mallyaCharacteristicsArray: [MallyaCharacteristicInfo] = []
    var isInPairingProcess = false
    var payload: MallyaConnectionStatusPayload?
    var sessionSeedPayload: MallyaSessionSeedPayload?
    var registrationID: UInt32 = 0
    var RID: UInt16 = 0
    let secretKey: [UInt8] = [0xbb, 0x6f, 0xec, 0x34, 0x4e, 0x4b, 0x02, 0xf5, 0x43, 0x3f, 0x03, 0x80 , 0xbf, 0x76, 0x4c,0x20]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanPeripheral()
    }
    
    func scanPeripheral() {
        centralManager
            .publisher(for: \.state)
            .sink { [weak self] state in
                guard state == .poweredOn else { return }
                let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                self?.centralManager.scanForPeripherals(withServices: [MallyaMetaDataServiceUUID.flextouch.cbUUID],
                                                        options: options)
            }
            .store(in: &bag)
    }
}

// MARK: - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            debugPrint("poweredOff")
        case .poweredOn:
            debugPrint("poweredOn")
        case .resetting:
            debugPrint("resetting")
        case .unauthorized:
            debugPrint("unauthorized")
        case .unknown:
            debugPrint("unknown")
        case .unsupported:
            debugPrint("unsupported")
        @unknown default:
            debugPrint("unknown state case")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let serviceData = advertisementData[AdvertisementDataKey.serviceData.key] as? [CBUUID: Data],
              let powerLevel = advertisementData[AdvertisementDataKey.powerLevel.key] as? Int else { return }
        let mallyaAdvertisementData = MallyaAdvertisementData(kCBAdvDataLocalName: advertisementData[AdvertisementDataKey.localName.key] as? String,
                                                              kCBAdvDataServiceData: serviceData,
                                                              kCBAdvDataTxPowerLevel: powerLevel)
        let mallyaPeripheralInfo = MallyaPeripheralInfo(peripheral: peripheral,
                                                        bluetoothIdentifier: peripheral.identifier.uuidString,
                                                        advertisementData: mallyaAdvertisementData)
//        guard mallyaPeripheralInfo.isNewDevice else { return }
        print("Peripheral \(mallyaPeripheralInfo)")
        peripheralInfo = mallyaPeripheralInfo
        central.stopScan()
        mallyaPeripheralInfo.peripheral.delegate = self
        centralManager.connect(mallyaPeripheralInfo.peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect to peripheral:\(peripheral)")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error as Any)
    }
}

// MARK: - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(error as Any)
        peripheral.services?.forEach({ service in
            let serviceUUIDType = MallyaServiceUUID(serviceUUID: service.uuid.uuidString)
            print(serviceUUIDType)
            peripheral.discoverCharacteristics(nil, for: service)
            print("service \(service)")
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        mallyaCharacteristicsArray += characteristics.map{ MallyaCharacteristicInfo(characteristic: $0) }
//        print("characteristic: \(mallyaCharacteristicsArray)")
        mallyaCharacteristicsArray.forEach { characteristic in
            switch characteristic.type {
            case .connectionStatus:
                peripheral.setNotifyValue(true, for: characteristic.characteristic)
                peripheral.readValue(for: characteristic.characteristic)
            case .registration:
//                peripheral.setNotifyValue(true, for: characteristic.characteristic)
//                peripheral.readValue(for: characteristic.characteristic)
                break
            case .sessionSeed:
                peripheral.setNotifyValue(true, for: characteristic.characteristic)
                peripheral.readValue(for: characteristic.characteristic)
            case .currentDeviceTime:
                peripheral.setNotifyValue(true, for: characteristic.characteristic)
            case .powerManagement:
                peripheral.setNotifyValue(true, for: characteristic.characteristic)
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
                print("didUpdate characteristic: \(characteristic)")
        //        print(characteristic.description)
        guard let value = characteristic.value else { return }
        let mallyaCharacteristic = MallyaCharacteristicInfo(characteristic: characteristic)
        switch mallyaCharacteristic.type {
        case .connectionStatus:
            guard let connectionStatusValue = characteristic.value else { return }
            let connectionStatusPayload = MallyaConnectionStatusPayload(connectionStatusValue)
            print(connectionStatusPayload as Any)
            switch connectionStatusPayload?.statusType {
            case .paired:
                guard !isInPairingProcess else { return }
                isInPairingProcess = true
                writeRegistrationCharacteristic(with: peripheral, characteristic: characteristic)
            case .registered:
                payload = connectionStatusPayload
                isInPairingProcess = false
                guard let sessionSeedCharacteristic = mallyaCharacteristicsArray.first(where: { $0.type == .sessionSeed }) else { return }
                peripheral.readValue(for: sessionSeedCharacteristic.characteristic)
            case .appTimeManagementVerified:
                guard let powerManagementCharacteristic = mallyaCharacteristicsArray.first(where: { $0.type == .powerManagement }) else { return }
                peripheral.readValue(for: powerManagementCharacteristic.characteristic)
            default:
                return
            }
        case .sessionSeed:
            sessionSeedPayload = MallyaSessionSeedPayload(value)
            guard let sessionSeedPayload = sessionSeedPayload,
                  !sessionSeedPayload.isSessionSeedEmpty else { return
                print("session seed empty")
            }
            let pairCurrentTimeData: [UInt8] = Array(repeating: 0, count: 4)
            let crcValue = Data(pairCurrentTimeData).crc16ccitt().bigEndianBytes
            guard let currentDeviceTimeRequestCharacteristic = mallyaCharacteristicsArray.first(where: { $0.type == .currentDeviceTimeRequest}) else { return }
            print("seed: \(Data(sessionSeedPayload.seed).hexString)")
            let encrpt = try? AesForBioCorp().doAES(forMallya: Data(pairCurrentTimeData + crcValue),
                                  keyIV: Data(sessionSeedPayload.seed),
                                  keyEK: Data(secretKey),
                                  context: CCOperation(kCCEncrypt))
//            let encrpt = encrypt(key: Data(secretKey), initializationVector: Data(sessionSeedPayload.seed), dataIn:  Data(pairCurrentTimeData + crcValue))
            guard let encryptedData = encrpt as? Data
            else { return }
            print("encryptedData: \(encryptedData.hexString)")
            peripheral.writeValue(encryptedData, for: currentDeviceTimeRequestCharacteristic.characteristic, type: .withoutResponse)
        case .currentDeviceTime:
            guard let sessionSeedPayload = sessionSeedPayload,
                  let decryptedValue = try? AesForBioCorp().doAES(forMallya: value,
                                                                              keyIV: Data(sessionSeedPayload.seed),
                                                                              keyEK: Data(secretKey),
                                                                              context: CCOperation(kCCDecrypt)) as Data else {
                print("decrypted error!!!!!!!!!")
                return }
            print(MallyaCurrentTimePayload(decryptedValue) as Any)
        case .powerManagement:
            guard  let sessionSeedPayload = sessionSeedPayload,
                   let decryptedValue = try? AesForBioCorp().doAES(forMallya: value,
                                                                                 keyIV: Data(sessionSeedPayload.seed),
                                                                                 keyEK: Data(secretKey),
                                                                                 context: CCOperation(kCCDecrypt)) as Data else {
                print("decrypted error!!!!!!!!!")
                return }
            let payload = MallyaPowerManagementPayload(decryptedValue)
            print(payload as Any)
        default:
            guard let value = characteristic.value else { return }
            print(characteristic)
            print(value)
            break
        }
    }
    
    func writeRegistrationCharacteristic(with peripheral: CBPeripheral, characteristic: CBCharacteristic) {
//        let randomKey = SymmetricKey(size: .bits128)
//        let secretKeyData = randomKey.withUnsafeBytes { Data($0) }
        var data: [UInt8] = []
        let registrationType: UInt8 = 0
        let isBluetoothAddressPrivacyEnabled: UInt8 = 1
        data += [registrationType, isBluetoothAddressPrivacyEnabled]
        data += secretKey
        data += Data(data).crc16ccitt().bigEndianBytes
        print(Data(data).hexString)
        print(data.map{ String($0, radix: 16)})
        guard let registrationCharacteristic = mallyaCharacteristicsArray.first(where: { $0.type == .registration }) else {
            print("NO REGISTRATION CHARACTERISTIC")
            return }
        peripheral.writeValue(Data(data),
                              for: registrationCharacteristic.characteristic,
                              type: .withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        print(characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//        print(characteristic)
    }
}

