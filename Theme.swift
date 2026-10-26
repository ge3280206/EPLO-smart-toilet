import SwiftUI

/// EPLO 品牌色板（与安卓版 #005670 主题一致）
enum EploColor {
    static let primary = Color(hex: 0x005670)
    static let primaryDark = Color(hex: 0x003D52)
    static let accent = Color(hex: 0x00A5C4)
    static let bg = Color(hex: 0xF2F5F8)
    static let surface = Color.white
    static let text = Color(hex: 0x0E1726)
    static let textSub = Color(hex: 0x6B7789)
    static let line = Color(hex: 0xE0E6ED)
    static let ok = Color(hex: 0x16A34A)
    static let warn = Color(hex: 0xD97706)
    static let chipBg = Color(hex: 0xE1EEF4)
    static let tagText = Color(hex: 0x8A97A8)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

/// 通用卡片样式
struct EploCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EploColor.surface)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(EploColor.line, lineWidth: 1)
            )
    }
}

/// 小标题（卡片顶部英文标签）
struct SectionTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .regular))
            .tracking(1.6)
            .foregroundColor(EploColor.tagText)
    }
}
