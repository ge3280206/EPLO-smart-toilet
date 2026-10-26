import SwiftUI

@main
struct EPLOApp: App {
    @StateObject private var device = DeviceManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(device)
                .preferredColorScheme(.light)
        }
    }
}
