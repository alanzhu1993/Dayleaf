import AppKit
import SwiftUI

// MARK: - Color Helpers

extension Color {
    /// 0xRRGGBB 十六进制构造。
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// 随系统/窗口外观（浅色或深色）自动切换的动态颜色。
    init(light: UInt, dark: UInt, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        let nsColor = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let hex = isDark ? dark : light
            let alpha = isDark ? darkAlpha : lightAlpha
            return NSColor(
                srgbRed: Double((hex >> 16) & 0xFF) / 255,
                green: Double((hex >> 8) & 0xFF) / 255,
                blue: Double(hex & 0xFF) / 255,
                alpha: alpha
            )
        }
        self.init(nsColor: nsColor)
    }
}

// MARK: - Window Appearance

/// 强制所在 NSWindow 的外观跟随选定主题。
/// 菜单栏弹窗里 .preferredColorScheme 常常不真正切换窗口外观，导致动态颜色和原生控件不变色；
/// 直接设 window.appearance 才能让浅/深色彻底切过去。
struct WindowAppearance: NSViewRepresentable {
    let scheme: ColorScheme

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        apply(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(from: nsView)
    }

    private func apply(from view: NSView) {
        let name: NSAppearance.Name = scheme == .dark ? .darkAqua : .aqua
        DispatchQueue.main.async {
            view.window?.appearance = NSAppearance(named: name)
        }
    }
}

extension View {
    /// 把当前视图所在窗口的外观锁定为指定主题（含 SwiftUI 环境 + AppKit 窗口）。
    func themedWindow(_ scheme: ColorScheme) -> some View {
        background { WindowAppearance(scheme: scheme) }
            .environment(\.colorScheme, scheme)
            .preferredColorScheme(scheme)
    }
}

// MARK: - Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }
    var label: String { self == .light ? "浅色" : "深色" }
    var colorScheme: ColorScheme { self == .light ? .light : .dark }
}

/// 全局主题存储键。各视图用 @AppStorage(AppThemeStore.key) 读写同一值。
enum AppThemeStore {
    static let key = "dayleaf.theme"
    static let `default` = AppTheme.dark.rawValue
}

// MARK: - Palette（随主题自动切换）

enum Palette {
    static let background = Color(light: 0xF4F4F6, dark: 0x1C1C1E)   // 弹窗底
    static let tile = Color(light: 0xFFFFFF, dark: 0x2C2C2E)         // 内容块
    static let control = Color(light: 0xE8E8EC, dark: 0x3A3A3C)      // 块内按钮/输入

    static let textPrimary = Color(light: 0x1C1C1E, dark: 0xF5F5F7)
    static let textSecondary = Color(light: 0x8A8A8E, dark: 0x8E8E93)
    static let textTertiary = Color(light: 0xB6B6BB, dark: 0x6E6E73)

    static let accent = Color(light: 0x007AFF, dark: 0x0A84FF)       // 专注身份色
    static let accentText = Color(light: 0x007AFF, dark: 0x409CFF)
    static let note = Color(light: 0x2FA56A, dark: 0x4CD787)         // 记录身份色（快速记录框 + 时间线记录圆点）
    static let warn = Color(light: 0xFF9500, dark: 0xFF9F0A)
    static let danger = Color(light: 0xD7322B, dark: 0xFF6961)
    static let dangerFill = Color(light: 0xF7D8D6, dark: 0x5A2A2A)

    static let separator = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.10, darkAlpha: 0.08)
    static let tileBorder = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.07, darkAlpha: 0.06)
    static let hoverFill = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.05, darkAlpha: 0.08)
}

// MARK: - Design Tokens

enum DS {
    static let pagePadding: CGFloat = 16
    static let sectionGap: CGFloat = 16
    static let cardPadding: CGFloat = 13
    static let cardGap: CGFloat = 10
    static let rowGap: CGFloat = 8

    static let cardRadius: CGFloat = 12
    static let controlRadius: CGFloat = 10

    static let popoverWidth: CGFloat = 380
    static let hairline: CGFloat = 0.75
}

// MARK: - Tile

extension View {
    /// 内容块：填充 + 极细描边。
    func tile(radius: CGFloat = DS.cardRadius, fill: Color = Palette.tile) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Palette.tileBorder, lineWidth: DS.hairline)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.9)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Soft Field

struct SoftFieldBackground: ViewModifier {
    /// 激活态：聚焦或鼠标悬停。激活时点亮 tint 身份色，未激活时为中性灰，所有输入框一致。
    var focused: Bool = false
    var elevated: Bool = false
    /// 该输入框激活时点亮的身份色，应与它对应的时间线圆点同色；为空则用默认蓝。
    var tint: Color? = nil

    private var activeColor: Color { tint ?? Palette.accent }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .fill(elevated ? Palette.control : Palette.tile)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .strokeBorder(
                        focused ? activeColor.opacity(0.9) : Palette.tileBorder,
                        lineWidth: focused ? 1 : DS.hairline
                    )
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func softField(focused: Bool = false, elevated: Bool = false, tint: Color? = nil) -> some View {
        modifier(SoftFieldBackground(focused: focused, elevated: elevated, tint: tint))
    }
}

// MARK: - Button Styles

/// 主操作：实心填充，默认系统蓝；可传 fill 换成模块身份色（如记录用绿）。
struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = Palette.accent
    var expand: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: expand ? .infinity : nil)
            .padding(.vertical, 9)
            .padding(.horizontal, expand ? 0 : 16)
            .background {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.78 : 1))
            }
            .contentShape(Rectangle())
    }
}

/// 次操作：浅灰/深灰块填充。
struct NeutralButtonStyle: ButtonStyle {
    var fill: Color = Palette.control
    var textColor: Color = Palette.textPrimary
    var expand: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(textColor)
            .frame(maxWidth: expand ? .infinity : nil)
            .padding(.vertical, 9)
            .padding(.horizontal, expand ? 0 : 14)
            .background {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.7 : 1))
            }
            .contentShape(Rectangle())
    }
}

/// 图标按钮：无底色，灰色，悬停略亮。
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {
        IconButtonBody(configuration: configuration, size: size)
    }

    private struct IconButtonBody: View {
        let configuration: ButtonStyle.Configuration
        let size: CGFloat
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(hovering ? Palette.textPrimary : Palette.textSecondary)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Palette.hoverFill.opacity(hovering ? 1 : 0))
                }
                .opacity(configuration.isPressed ? 0.6 : 1)
                .onHover { hovering = $0 }
                .contentShape(Rectangle())
        }
    }
}

/// 页脚文字按钮：小号图标+文字。用于「设置」「关于」。
struct FooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FooterBody(configuration: configuration)
    }

    private struct FooterBody: View {
        let configuration: ButtonStyle.Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.caption.weight(.medium))
                .foregroundStyle(hovering ? Palette.textPrimary : Palette.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Palette.hoverFill.opacity(hovering ? 1 : 0))
                }
                .opacity(configuration.isPressed ? 0.6 : 1)
                .onHover { hovering = $0 }
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isError ? Palette.warn : Palette.accentText)
            Text(text)
                .font(.callout.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
            Capsule(style: .continuous).fill(Palette.control)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Palette.tileBorder, lineWidth: DS.hairline)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}
