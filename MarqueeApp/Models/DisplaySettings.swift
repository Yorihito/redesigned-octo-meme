import SwiftUI
import Observation

@Observable
final class DisplaySettings {
    var text: String = "HELLO WORLD"
    var mode: DisplayMode = .still

    // dot appearance
    var dotSize: CGFloat = 8.0
    var dotSpacing: CGFloat = 1.5
    var foregroundColor: LEDColor = .orange
    var backgroundColor: LEDColor = .black

    // auto scroll
    var scrollSpeed: Double = 80.0   // pt/sec
    var loopEnabled: Bool = true
    var loopGapSeconds: Double = 1.0

    // spatial
    var spatialSensitivity: Double = 1.0

    var fgColor: Color { foregroundColor.color }
    var bgColor: Color { backgroundColor.color }

    // glyph metrics derived from dotSize
    var glyphWidth: CGFloat { dotSize * 5 + dotSpacing * 4 }
    var glyphHeight: CGFloat { dotSize * 7 + dotSpacing * 6 }
    var charSpacing: CGFloat { dotSize * 1 }
}

enum LEDColor: String, CaseIterable, Identifiable {
    case orange, red, green, white, yellow, cyan, black

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .red:    return Color(red: 1.0, green: 0.1, blue: 0.0)
        case .green:  return Color(red: 0.0, green: 1.0, blue: 0.2)
        case .white:  return .white
        case .yellow: return Color(red: 1.0, green: 0.95, blue: 0.0)
        case .cyan:   return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .black:  return .black
        }
    }
}
