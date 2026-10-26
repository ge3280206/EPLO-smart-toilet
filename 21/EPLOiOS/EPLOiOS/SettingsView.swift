import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dm: DeviceManager

    @State private var userId = Prefs.shared.userId
    @State private var soundOn = Prefs.shared.soundOn
    @State private var transport = Prefs.shared.transport
    @State private var showUuidSheet = false
    @State private var svc = Prefs.shared.serviceUuid
    @State private var wr = Prefs.shared.writeUuid
    @State private var nt = Prefs.shared.notifyUuid
    @State private var infoTitle = ""
    @State private var infoBody = ""
    @State private var showInfo = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.2.2"
    }

    private var coverage: (Int, Int) {
        let list = dm.features
        return (list.count, list.filter { $0.canControl }.count)
    }

    var body: some View {
        NavigationView {
            List {
                // MARK: Preferences
                Section {
                    Picker("User ID", selection: $userId) {
                        ForEach(1...4, id: \.self) { i in
                            Text("User \(i)").tag(i)
                        }
                    }
                    .onChange(of: userId) { v in
                        Prefs.shared.userId = v
                        dm.send(cmd: 0x64, value: v)
                    }

                    Toggle("Key Sound", isOn: $soundOn)
                        .tint(EploColor.primary)
                        .onChange(of: soundOn) { v in Prefs.shared.soundOn = v }

                    Picker("Default Connection", selection: $transport) {
                        Text("Bluetooth BLE").tag("ble")
                        Text("Wi-Fi LAN").tag("wifi")
                    }
                    .onChange(of: transport) { v in dm.switchTransport(v) }
                } header: {
                    Text("PREFERENCES")
                }

                // MARK: Protocol
                Section {
                    Button {
                        svc = Prefs.shared.serviceUuid
                        wr = Prefs.shared.writeUuid
                        nt = Prefs.shared.notifyUuid
                        showUuidSheet = true
                    } label: {
                        row("BLE Service / Characteristics",
                            "Must match the toilet module firmware. Tap to edit")
                    }

                    Button {
                        info("Wi-Fi Default Address",
                             "\(Prefs.shared.wifiHost) : \(Prefs.shared.wifiPort)\n\nEdit it on the Connect tab (Wi-Fi).")
                    } label: {
                        row("Wi-Fi Default Address",
                            "\(Prefs.shared.wifiHost) : \(Prefs.shared.wifiPort)")
                    }

                    Button {
                        info("Frame Format",
                             "Header: AA 55\nCommand: 1 byte\nLength: 1 byte\nData: N bytes\nCRC8: 1 byte (CRC-8/MAXIM)\n\nThe full command table is in EPLO_Protocol_Commands.md shipped with the project.\nIf the firmware uses another format, only Protocol.swift needs changes.")
                    } label: {
                        row("Frame Format", "AA 55 | CMD | LEN | DATA | CRC8")
                    }
                } header: {
                    Text("PROTOCOL")
                }

                // MARK: Maintenance
                Section {
                    Button {
                        info("Nozzle Cleaning",
                             "With the seat unoccupied, turn the knob clockwise to extend the nozzle, remove and clean it separately, then press the knob to retract. Do not pull the nozzle bar.")
                    } label: {
                        row("Nozzle Cleaning", "Extend the nozzle when seat is unoccupied")
                    }

                    Button {
                        info("Filter Cleaning",
                             "Power off and close the angle valve → unscrew the valve nut → take out the filter, wash with running water and a brush → reinstall → reopen the valve.")
                    } label: {
                        row("Filter Cleaning", "Clean the angle-valve filter when flow weakens")
                    }

                    Button {
                        info("Storage & Emergency",
                             "With a battery box installed, long-press the knob (about 3 s) to flush during a power outage; without a battery, pour about 8 L (2.1 Gal) of water into the bowl.\n\nLong-term storage: flush → close the valve → power off → disconnect the hose at the valve to drain, then reconnect. Adding antifreeze is recommended.")
                    } label: {
                        row("Power Off / Long-term Storage",
                            "Drain for freeze protection and emergency flush")
                    }

                    Button {
                        info("Contact Us",
                             "Support: service@eplo.com\nWebsite: www.eplo.com\nWarranty: 2 years whole unit / 10 years ceramics")
                    } label: {
                        row("Customer Support", "service@eplo.com · www.eplo.com")
                    }
                } header: {
                    Text("MAINTENANCE & SUPPORT")
                }

                // MARK: About
                Section {
                    HStack {
                        Text("EPLO Smart")
                        Spacer()
                        Text("Version \(version) · iOS App")
                            .foregroundColor(EploColor.textSub)
                    }

                    Button {
                        info("Feature Coverage",
                             "Washing 6, Drying 6, Seat 4, Flush 6, Hygiene 8, Lid & Smart 15, Safety 7 (hardware level, display only).\n\n\(coverage.0) features, \(coverage.1) remotely controllable.")
                    } label: {
                        row("Feature Coverage",
                            "\(coverage.0) features, \(coverage.1) remotely controllable")
                    }

                    HStack {
                        Text("Connection")
                        Spacer()
                        Text("Bluetooth BLE / Wi-Fi LAN")
                            .foregroundColor(EploColor.textSub)
                    }
                } header: {
                    Text("ABOUT")
                }

                Section {
                    Text("EPLO · Smart Toilet Control\nAll rights reserved")
                        .font(.system(size: 10))
                        .foregroundColor(EploColor.tagText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitle("Settings", displayMode: .inline)
            .sheet(isPresented: $showUuidSheet) { uuidSheet }
            .alert(infoTitle, isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(infoBody)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func row(_ title: String, _ sub: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(EploColor.text)
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(EploColor.textSub)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0xB6C0CE))
        }
    }

    private var uuidSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("SERVICE")) {
                    TextField("Service UUID", text: $svc)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: 12, design: .monospaced))
                }
                Section(header: Text("CHARACTERISTICS")) {
                    TextField("Write UUID", text: $wr)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: 12, design: .monospaced))
                    TextField("Notify UUID", text: $nt)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: 12, design: .monospaced))
                }
                Section(footer: Text("Takes effect after reconnecting.")) {
                    Button("Save") {
                        Prefs.shared.serviceUuid = svc
                        Prefs.shared.writeUuid = wr
                        Prefs.shared.notifyUuid = nt
                        showUuidSheet = false
                    }
                }
            }
            .navigationBarTitle("BLE UUIDs", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showUuidSheet = false }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func info(_ title: String, _ body: String) {
        infoTitle = title
        infoBody = body
        showInfo = true
    }
}
