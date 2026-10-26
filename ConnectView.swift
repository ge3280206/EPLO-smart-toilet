import SwiftUI

struct ConnectView: View {
    @EnvironmentObject var dm: DeviceManager
    @ObservedObject private var ble = DeviceManager.shared.ble

    @State private var mode: String = Prefs.shared.transport
    @State private var host: String = Prefs.shared.wifiHost
    @State private var port: String = String(Prefs.shared.wifiPort)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                modeCard

                if mode == "ble" { bleCard } else { wifiCard }

                logCard
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 通道选择

    private var modeCard: some View {
        EploCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Connection Mode")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EploColor.text)
                SectionTag(text: "BLUETOOTH OR WI-FI LAN")

                Picker("Mode", selection: $mode) {
                    Text("Bluetooth BLE").tag("ble")
                    Text("Wi-Fi LAN").tag("wifi")
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { newValue in
                    dm.switchTransport(newValue)
                }
            }
        }
    }

    // MARK: - 蓝牙

    private var bleCard: some View {
        EploCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Nearby EPLO Devices")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(EploColor.text)
                    Spacer()
                    Button {
                        if ble.isScanning { ble.stopScan() } else { ble.startScan() }
                    } label: {
                        Text(ble.isScanning ? "Stop" : "Scan")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(EploColor.primary)
                            .cornerRadius(14)
                    }
                }

                if ble.devices.isEmpty {
                    Text(ble.isScanning ? "Scanning nearby devices…" : "Bluetooth not connected · Scan for nearby EPLO devices")
                        .font(.system(size: 11))
                        .foregroundColor(EploColor.textSub)
                        .padding(.vertical, 8)
                } else {
                    ForEach(ble.devices) { d in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(EploColor.text)
                                Text("\(d.rssi) dBm")
                                    .font(.system(size: 10))
                                    .foregroundColor(EploColor.textSub)
                            }
                            Spacer()
                            Button {
                                dm.connectBLE(d)
                            } label: {
                                Text("Connect")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(EploColor.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(EploColor.primary, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.vertical, 6)

                        if d.id != ble.devices.last?.id {
                            Divider().background(EploColor.line)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Wi-Fi

    private var wifiCard: some View {
        EploCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Wi-Fi LAN Connection")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EploColor.text)

                Text("Wi-Fi not connected · Phone and toilet must share the same network")
                    .font(.system(size: 11))
                    .foregroundColor(EploColor.textSub)

                HStack(spacing: 8) {
                    TextField("Device IP", text: $host)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .frame(width: 76)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    Button {
                        Prefs.shared.wifiHost = host
                        Prefs.shared.wifiPort = Int(port) ?? 8266
                        dm.connectWiFi(host: host, port: Int(port) ?? 8266)
                    } label: {
                        Text("Connect")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(EploColor.primary)
                            .cornerRadius(12)
                    }

                    Button {
                        dm.disconnect()
                    } label: {
                        Text("Disconnect")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(EploColor.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(EploColor.primary, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - 通信日志

    private var logCard: some View {
        EploCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("COMM LOG")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.4)
                        .foregroundColor(EploColor.tagText)
                    Spacer()
                    Button("Clear") {
                        dm.logs.removeAll()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(EploColor.primary)
                }

                if dm.logs.isEmpty {
                    Text("No traffic yet")
                        .font(.system(size: 11))
                        .foregroundColor(EploColor.textSub)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(dm.logs.reversed().prefix(60)) { line in
                                Text(line.text)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(EploColor.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }
}
