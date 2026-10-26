import Foundation
import Combine

enum ConnState {
    case offline, connecting, online

    var title: String {
        switch self {
        case .offline: return "OFFLINE"
        case .connecting: return "CONNECTING"
        case .online: return "ONLINE"
        }
    }
}

struct LogLine: Identifiable {
    let id = UUID()
    let time: Date
    let text: String
}

/// 统一设备管理：BLE / Wi-Fi TCP 双通道 + 功能状态 + 通信日志
final class DeviceManager: ObservableObject {

    static let shared = DeviceManager()

    @Published private(set) var state: ConnState = .offline
    @Published private(set) var connectedDevice: String = ""
    @Published var transport: String = Prefs.shared.transport
    @Published var features: [Feature] = FeatureRepo.build()
    @Published var logs: [LogLine] = []
    @Published private(set) var lastAction: String = "STANDBY"

    let ble = BLEManager()
    let tcp = TCPClient()
    let prefs = Prefs.shared

    private init() {
        for i in features.indices {
            let f = features[i]
            features[i].value = prefs.featureValue(f.id, f.value)
        }
        wire()
    }

    private func wire() {
        ble.onLog = { [weak self] s in self?.log(s) }
        ble.onConnected = { [weak self] name in
            guard let self = self else { return }
            self.connectedDevice = name
            self.setState(.online)
            self.queryStatus()
        }
        ble.onDisconnected = { [weak self] _ in self?.setState(.offline) }
        ble.onData = { _ in }

        tcp.onLog = { [weak self] s in self?.log(s) }
        tcp.onConnected = { [weak self] host in
            guard let self = self else { return }
            self.connectedDevice = host
            self.setState(.online)
            self.queryStatus()
        }
        tcp.onDisconnected = { [weak self] _ in self?.setState(.offline) }
        tcp.onData = { _ in }
    }

    private func setState(_ s: ConnState) {
        DispatchQueue.main.async {
            self.state = s
            if s == .offline { self.connectedDevice = "" }
        }
    }

    var isConnected: Bool { state == .online }

    // MARK: - 连接

    func connectBLE(_ device: BleDevice) {
        state = .connecting
        ble.connect(device)
    }

    func connectWiFi(host: String, port: Int) {
        state = .connecting
        tcp.connect(host: host, port: UInt16(port))
    }

    func disconnect() {
        ble.disconnect()
        tcp.disconnect()
        state = .offline
        connectedDevice = ""
        log("Disconnected")
    }

    func switchTransport(_ t: String) {
        transport = t
        prefs.transport = t
        disconnect()
    }

    // MARK: - 发送

    func send(cmd: UInt8, value: Int?) {
        let data = EploProtocol.frame(cmd: cmd, value: value)
        if transport == "wifi" {
            tcp.send(data)
        } else {
            ble.write(data)
        }
    }

    /// 执行某个功能（开关/档位/动作统一入口）
    func sendFeature(_ f: Feature) {
        guard isConnected else {
            log("Not connected, command not sent")
            return
        }
        switch f.kind {
        case .action, .toggle:
            send(cmd: f.cmd, value: f.kind == .toggle ? (f.isOn ? 1 : 0) : nil)
        case .level:
            send(cmd: f.cmd, value: f.value)
        case .info:
            break
        }
        lastAction = f.name
    }

    func stop() {
        guard isConnected else { return }
        send(cmd: 0x00, value: nil)
        lastAction = "STOPPED"
    }

    func queryStatus() {
        send(cmd: 0x70, value: nil)
    }

    // MARK: - 功能读写

    func update(_ f: Feature) {
        guard let i = features.firstIndex(where: { $0.id == f.id }) else { return }
        features[i].value = f.value
        prefs.setFeatureValue(f.id, f.value)
    }

    func feature(_ id: String) -> Feature? {
        features.first { $0.id == id }
    }

    func levelText(_ id: String) -> String {
        guard let f = feature(id) else { return "--" }
        if f.value == f.minValue { return f.cat == .seat || f.cat == .wash || f.cat == .dry ? "Room" : f.levelText }
        return f.levelText
    }

    // MARK: - 日志

    func log(_ s: String) {
        let line = LogLine(time: Date(), text: s)
        DispatchQueue.main.async {
            self.logs.append(line)
            if self.logs.count > 200 {
                self.logs.removeFirst(self.logs.count - 200)
            }
        }
    }
}
