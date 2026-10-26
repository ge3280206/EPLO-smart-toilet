import Foundation
import CoreBluetooth

struct BleDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
}

/// 蓝牙 BLE 通道（CoreBluetooth）。默认使用 Nordic UART 透传 UUID，可在设置中修改。
final class BLEManager: NSObject, ObservableObject {

    @Published private(set) var isScanning = false
    @Published private(set) var devices: [BleDevice] = []
    @Published private(set) var connectedName: String?

    var onLog: ((String) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: ((String) -> Void)?
    var onData: ((Data) -> Void)?

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?
    private var pendingReconnect = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    var isConnected: Bool { peripheral?.state == .connected && writeChar != nil }

    // MARK: - 扫描

    func startScan() {
        guard central.state == .poweredOn else {
            onLog?("Bluetooth is not ready (state \(central.state.rawValue))")
            return
        }
        devices.removeAll()
        isScanning = true
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        onLog?("Scanning nearby devices…")
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        onLog?("Scan stopped")
    }

    // MARK: - 连接

    func connect(_ device: BleDevice) {
        guard let p = central.retrievePeripherals(withIdentifiers: [device.id]).first else {
            onLog?("Device no longer available, scan again")
            return
        }
        stopScan()
        peripheral = p
        p.delegate = self
        pendingReconnect = true
        onLog?("Connecting to \(device.name)")
        central.connect(p, options: nil)
    }

    func disconnect() {
        pendingReconnect = false
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
        }
        peripheral = nil
        writeChar = nil
        notifyChar = nil
        connectedName = nil
    }

    // MARK: - 发送

    func write(_ data: Data) {
        guard let p = peripheral, let c = writeChar else {
            onLog?("Send failed: not connected")
            return
        }
        let type: CBCharacteristicWriteType = c.properties.contains(.write) ? .withResponse : .withoutResponse
        p.writeValue(data, for: c, type: type)
        onLog?("TX → " + EploProtocol.hex(data))
    }
}

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            onLog?("Bluetooth ready")
        case .poweredOff:
            onLog?("Bluetooth is off")
        case .unauthorized:
            onLog?("Bluetooth permission denied — enable it in iOS Settings")
        case .unsupported:
            onLog?("Bluetooth not supported on this device")
        default:
            onLog?("Bluetooth state: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? "(Unnamed device)"
        let item = BleDevice(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
        if let idx = devices.firstIndex(where: { $0.id == item.id }) {
            devices[idx] = item
        } else {
            devices.append(item)
            devices.sort { a, b in
                let ae = a.name.uppercased().hasPrefix("EPLO")
                let be = b.name.uppercased().hasPrefix("EPLO")
                if ae != be { return ae }
                return a.rssi > b.rssi
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onLog?("Connected, discovering services")
        connectedName = peripheral.name
        peripheral.delegate = self
        let svc = CBUUID(string: Prefs.shared.serviceUuid)
        peripheral.discoverServices([svc])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        onLog?("Connect failed: \(error?.localizedDescription ?? "unknown")")
        onDisconnected?("Connect failed")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        onLog?("Disconnected" + (error == nil ? "" : " (\(error!.localizedDescription))"))
        writeChar = nil
        notifyChar = nil
        connectedName = nil
        onDisconnected?("Disconnected")
    }
}

extension BLEManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error {
            onLog?("Discover services failed: \(e.localizedDescription)")
        }
        guard let services = peripheral.services, !services.isEmpty else {
            onLog?("No matching service. Check the UUID in Settings")
            // 回退：发现全部服务
            peripheral.discoverServices(nil)
            return
        }
        for s in services {
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let chars = service.characteristics else { return }
        let wr = CBUUID(string: Prefs.shared.writeUuid)
        let nt = CBUUID(string: Prefs.shared.notifyUuid)

        for c in chars {
            if c.uuid == wr { writeChar = c }
            if c.uuid == nt { notifyChar = c }
        }
        // 回退：找任意可写特征
        if writeChar == nil {
            writeChar = chars.first { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }
            if let w = writeChar {
                onLog?("Fallback write characteristic: \(w.uuid.uuidString)")
            }
        }
        // 回退：找任意通知特征
        if notifyChar == nil {
            notifyChar = chars.first { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
        }
        if let n = notifyChar {
            peripheral.setNotifyValue(true, for: n)
        }

        if writeChar != nil {
            onLog?("Channel ready, commands can be sent")
            onConnected?(connectedName ?? "EPLO Device")
        } else {
            onLog?("No writable characteristic found. Check protocol settings")
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }
        onLog?("RX ← " + EploProtocol.hex(data))
        onData?(data)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let e = error {
            onLog?("Write error: \(e.localizedDescription)")
        }
    }
}
