import Foundation

struct LightColorThemeFactory: ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> Color {
        switch style {
        case .primary: return Color(red: 0, green: 0, blue: 0)
        case .secondary: return Color(red: 153, green: 153, blue: 153)
        case .warning: return Color(red: 255, green: 59, blue: 48)
        }
    }

    func backgroundColor(_ style: MEGAColor.Background) -> Color {
        switch style {
        case .primary: return Color(red: 255, green: 255, blue: 255)
        case .warning: return Color(red: 255, green: 204, blue: 0, alpha: 38)
        case .enabled: return Color(red: 0, green: 168, blue: 134, alpha: 255)
        case .disabled: return Color(red: 153, green: 153, blue: 153, alpha: 255)
        case .highlighted: return Color(red: 0, green: 168, blue: 134, alpha: 204)
        }
    }

    func borderColor(_ style: MEGAColor.Border) -> Color {
        switch style {
        case .primary: return Color(red: 0, green: 0, blue: 0, alpha: 38)
        case .warning: return Color(red: 255, green: 204, blue: 0)
        }
    }

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonTextColorFactory()
        }
    }

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonBackgroundColorFactory()
        }
    }

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> Color {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }

    func shadowColor(_ style: MEGAColor.Shadow) -> Color {
        switch style {
        case .primary: return Color(red: 0, green: 0, blue: 0)
        }
    }
}
