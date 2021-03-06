import Foundation

enum MEGAColor {

    enum CustomViewBackground: Hashable {
        case warning
    }

    enum ThemeButton: Hashable {
        case primary
        case secondary
    }

    enum Text: Hashable {
        case primary
        case secondary
        
        case warning
    }

    enum Background: Hashable {
        case primary

        case warning
        case enabled
        case disabled
        case highlighted
    }

    enum Shadow: Hashable {
        case primary
    }

    enum Border: Hashable {
        case primary
        case warning
    }

    enum Independent: Hashable {
        case bright
    }
}
