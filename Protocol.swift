import Foundation

/// 通信协议：AA 55 | CMD | LEN | PAYLOAD | CRC8(MAXIM)
/// 与安卓版 Protocol.java 完全一致；模组固件定稿后只需改这里的帧格式与 Feature 里的 cmd。
enum EploProtocol {

    static let head1: UInt8 = 0xAA
    static let head2: UInt8 = 0x55

    static func frame(cmd: UInt8, value: Int?) -> Data {
        var bytes: [UInt8] = [head1, head2, cmd]
        if let v = value {
            bytes.append(1)
            bytes.append(UInt8(truncatingIfNeeded: v))
        } else {
            bytes.append(0)
        }
        let crc = crc8(bytes, offset: 2, length: bytes.count - 2)
        bytes.append(crc)
        return Data(bytes)
    }

    /// CRC-8/MAXIM（多项式 0x31，初值 0x00）
    static func crc8(_ data: [UInt8], offset: Int, length: Int) -> UInt8 {
        var crc: UInt8 = 0x00
        let end = min(data.count, offset + length)
        var i = offset
        while i < end {
            crc ^= data[i]
            for _ in 0..<8 {
                if (crc & 0x01) != 0 {
                    crc = (crc >> 1) ^ 0x8C
                } else {
                    crc >>= 1
                }
            }
            i += 1
        }
        return crc
    }

    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
