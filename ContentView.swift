import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dm: DeviceManager
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                switch tab {
                case 0: ControlView()
                case 1: ConnectView()
                default: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(EploColor.bg.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image("logo_eplo")
                .resizable()
                .scaledToFit()
                .frame(height: 26)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(dm.state == .online ? EploColor.ok : EploColor.warn)
                    .frame(width: 7, height: 7)
                Text(dm.state.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .tracking(0.6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.16))
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [EploColor.primary, EploColor.primaryDark],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Control", "slider.horizontal.3")
            tabButton(1, "Connect", "antenna.radiowaves.left.and.right")
            tabButton(2, "Settings", "gearshape")
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(EploColor.line).frame(height: 1), alignment: .top)
    }

    private func tabButton(_ index: Int, _ title: String, _ icon: String) -> some View {
        Button {
            tab = index
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(tab == index ? EploColor.primary : EploColor.textSub)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DeviceManager.shared)
    }
}
