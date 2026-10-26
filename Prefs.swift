import Foundation

/// 本地配置（对应安卓版 Prefs）
final class Prefs {

    static let shared = Prefs()

    private let d = UserDefaults.standard

    private init() {
        d.register(defaults: [
            "transport": "ble",
            "wifi_host": "192.168.1.100",
            "wifi_port": 8266,
            "svc_uuid": "6E400001-B5A3-F393-E0A9-E50E24DCCA9E",
            "wr_uuid": "6E400002-B5A3-F393-E0A9-E50E24DCCA9E",
            "nt_uuid": "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
            "user_id": 1,
            "sound": true
        ])
    }

    var transport: String {
        get { d.string(forKey: "transport") ?? "ble" }
        set { d.set(newValue, forKey: "transport") }
    }

    var wifiHost: String {
        get { d.string(forKey: "wifi_host") ?? "192.168.1.100" }
        set { d.set(newValue, forKey: "wifi_host") }
    }

    var wifiPort: Int {
        get { d.integer(forKey: "wifi_port") }
        set { d.set(newValue, forKey: "wifi_port") }
    }

    var serviceUuid: String {
        get { d.string(forKey: "svc_uuid") ?? "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" }
        set { d.set(newValue, forKey: "svc_uuid") }
    }

    var writeUuid: String {
        get { d.string(forKey: "wr_uuid") ?? "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" }
        set { d.set(newValue, forKey: "wr_uuid") }
    }

    var notifyUuid: String {
        get { d.string(forKey: "nt_uuid") ?? "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" }
        set { d.set(newValue, forKey: "nt_uuid") }
    }

    var userId: Int {
        get { d.integer(forKey: "user_id") }
        set { d.set(newValue, forKey: "user_id") }
    }

    var soundOn: Bool {
        get { d.bool(forKey: "sound") }
        set { d.set(newValue, forKey: "sound") }
    }

    func featureValue(_ key: String, _ def: Int) -> Int {
        d.object(forKey: "f_" + key) == nil ? def : d.integer(forKey: "f_" + key)
    }

    func setFeatureValue(_ key: String, _ v: Int) {
        d.set(v, forKey: "f_" + key)
    }
}
