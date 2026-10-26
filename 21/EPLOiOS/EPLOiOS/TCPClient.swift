import Foundation
import Network

/// Wi-Fi 局域网 TCP 通道（马桶 WiFi 模组默认 8266 端口）
final class TCPClient {

    var onLog: ((String) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: ((String) -> Void)?
    var onData: ((Data) -> Void)?

    private var connection: NWConnection?
    private var queue = DispatchQueue(label: "eplo.tcp")
    private(set) var isConnected = false

    func connect(host: String, port: UInt16) {
        disconnect()
        guard let p = NWEndpoint.Port(rawValue: port) else { return }
        let conn = NWConnection(host: NWEndpoint.Host(host), port: p, using: .tcp)
        connection = conn
        onLog?("Connecting to \(host):\(port)")

        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnected = true
                self.onLog?("TCP established")
                self.onConnected?(host)
                self.receiveLoop(conn)
            case .failed(let err):
                self.isConnected = false
                self.onLog?("Connect failed: \(err.localizedDescription)")
                self.onDisconnected?("Connect failed")
            case .cancelled:
                self.isConnected = false
            default:
                break
            }
        }
        conn.start(queue: queue)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    func send(_ data: Data) {
        guard let conn = connection, isConnected else {
            onLog?("Send failed: not connected")
            return
        }
        conn.send(content: data, completion: .contentProcessed { [weak self] error in
            if let e = error {
                self?.onLog?("Send error: \(e.localizedDescription)")
            }
        })
        onLog?("TX → " + EploProtocol.hex(data))
    }

    private func receiveLoop(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let d = data, !d.isEmpty {
                self.onLog?("RX ← " + EploProtocol.hex(d))
                self.onData?(d)
            }
            if let e = error {
                self.onLog?("Reader ended: \(e.localizedDescription)")
                self.isConnected = false
                self.onDisconnected?("Disconnected")
                return
            }
            if isComplete {
                self.isConnected = false
                self.onLog?("Disconnected by device")
                self.onDisconnected?("Disconnected")
                return
            }
            self.receiveLoop(conn)
        }
    }
}
