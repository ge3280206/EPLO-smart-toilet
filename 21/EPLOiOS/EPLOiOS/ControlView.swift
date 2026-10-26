import SwiftUI

struct ControlView: View {
    @EnvironmentObject var dm: DeviceManager
    @State private var filter: FeatureCat? = nil
    @State private var showInfo = false
    @State private var infoTitle = ""
    @State private var infoBody = ""

    private var shown: [Feature] {
        guard let c = filter else { return dm.features }
        return dm.features.filter { $0.cat == c }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                statusCard

                if dm.state != .online {
                    offlineBanner
                }

                categoryChips

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                          spacing: 10) {
                    ForEach(shown) { f in
                        FeatureCard(feature: f,
                                    onAction: { act($0) },
                                    onToggle: { f2, on in toggle(f2, on) },
                                    onLevel: { f2, v in level(f2, v) },
                                    onInfo: { showInfo($0) })
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
            .padding(.top, 12)
        }
        .alert(infoTitle, isPresented: $showInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(infoBody)
        }
    }

    // MARK: - 状态卡

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(dm.connectedDevice.isEmpty
                     ? "EPLO Smart Toilet · \(dm.transport == "wifi" ? "WiFi" : "BLE")"
                     : dm.connectedDevice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(EploColor.text)
                    .lineLimit(1)

                Spacer()

                Text(dm.lastAction)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(EploColor.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(EploColor.chipBg)
                    .cornerRadius(12)
            }

            HStack(spacing: 0) {
                stat("WATER TEMP", dm.levelText("water_temp"))
                stat("SEAT TEMP", dm.levelText("seat_temp"))
                stat("DRY TEMP", dm.levelText("dry_temp"))
            }

            HStack(spacing: 8) {
                quickBtn("REAR", .outlined) { act(id: "rear_wash") }
                quickBtn("FRONT", .outlined) { act(id: "front_wash") }
                quickBtn("DRY", .outlined) { act(id: "dryer") }
                quickBtn("STOP", .filled) {
                    if dm.isConnected { dm.stop() } else { requireConnect() }
                }
            }
        }
        .padding(16)
        .background(EploColor.surface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(EploColor.line, lineWidth: 1))
        .padding(.horizontal, 14)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(EploColor.textSub)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(EploColor.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum QuickStyle { case outlined, filled }

    private func quickBtn(_ title: String, _ style: QuickStyle, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundColor(style == .filled ? .white : EploColor.text)
                .background(style == .filled ? EploColor.primary : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style == .filled ? Color.clear : EploColor.line, lineWidth: 1)
                )
        }
    }

    // MARK: - 未连接横幅

    private var offlineBanner: some View {
        Button {
            requireConnect()
        } label: {
            Text("⚠  Not connected — TAP HERE to connect the toilet")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(EploColor.primary)
                .cornerRadius(12)
        }
        .padding(.horizontal, 14)
    }

    private func requireConnect() {
        infoTitle = "Not connected"
        infoBody = "Go to the Connect tab and pair the toilet over Bluetooth, or enter the Wi-Fi LAN address."
        showInfo = true
    }

    // MARK: - 分类筛选

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", nil)
                ForEach(FeatureCat.allCases) { c in
                    chip(c.title, c)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func chip(_ title: String, _ cat: FeatureCat?) -> some View {
        let active = filter == cat
        return Button {
            filter = cat
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(active ? .white : EploColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? EploColor.primary : EploColor.chipBg)
                .cornerRadius(16)
        }
    }

    // MARK: - 动作

    private func act(id: String) {
        guard let f = dm.feature(id) else { return }
        act(f)
    }

    private func act(_ f: Feature) {
        guard dm.isConnected else {
            requireConnect()
            return
        }
        dm.sendFeature(f)
    }

    private func toggle(_ f: Feature, _ on: Bool) {
        guard dm.isConnected else {
            requireConnect()
            return
        }
        var copy = f
        copy.value = on ? 1 : 0
        dm.update(copy)
        dm.sendFeature(copy)
    }

    private func level(_ f: Feature, _ v: Int) {
        guard dm.isConnected else {
            requireConnect()
            return
        }
        var copy = f
        copy.value = max(f.minValue, min(f.maxValue, v))
        dm.update(copy)
        dm.sendFeature(copy)
    }

    private func showInfo(_ f: Feature) {
        infoTitle = f.name
        infoBody = f.note.isEmpty
            ? "Implemented by the toilet hardware. No app setting needed."
            : f.note + "\n\nHardware-level design. For reference only."
        showInfo = true
    }
}

// MARK: - 功能卡片

private struct FeatureCard: View {
    let feature: Feature
    let onAction: (Feature) -> Void
    let onToggle: (Feature, Bool) -> Void
    let onLevel: (Feature, Int) -> Void
    let onInfo: (Feature) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(EploColor.primary)
                    .frame(width: 3, height: 14)
                Text(feature.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(EploColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }

            Text(feature.sub)
                .font(.system(size: 9))
                .foregroundColor(EploColor.textSub)
                .lineLimit(1)

            Spacer(minLength: 0)

            content
        }
        .padding(11)
        .frame(height: 118, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(EploColor.line, lineWidth: 1))
    }

    @ViewBuilder
    private var content: some View {
        switch feature.kind {
        case .toggle:
            HStack {
                Text(feature.isOn ? "ON" : "OFF")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(feature.isOn ? EploColor.ok : EploColor.textSub)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { feature.isOn },
                    set: { onToggle(feature, $0) }
                ))
                .labelsHidden()
                .scaleEffect(0.8)
                .tint(EploColor.primary)
            }

        case .level:
            HStack(spacing: 6) {
                stepButton("−") { onLevel(feature, feature.value - 1) }
                VStack(spacing: 0) {
                    Text(feature.levelText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(EploColor.primary)
                    Text("\(feature.value)/\(feature.maxValue)")
                        .font(.system(size: 8))
                        .foregroundColor(EploColor.textSub)
                }
                .frame(maxWidth: .infinity)
                stepButton("+") { onLevel(feature, feature.value + 1) }
            }

        case .action:
            Button {
                onAction(feature)
            } label: {
                Text("Run")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(EploColor.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(EploColor.chipBg)
                    .cornerRadius(9)
            }

        case .info:
            Button {
                onInfo(feature)
            } label: {
                Text("Hardware · details")
                    .font(.system(size: 10))
                    .foregroundColor(EploColor.textSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(Color(hex: 0xF4F6F9))
                    .cornerRadius(9)
            }
        }
    }

    private func stepButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(EploColor.primary)
                .frame(width: 30, height: 30)
                .background(EploColor.chipBg)
                .cornerRadius(8)
        }
    }
}
