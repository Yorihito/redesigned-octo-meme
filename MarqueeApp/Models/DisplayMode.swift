import Foundation

enum DisplayMode: String, CaseIterable, Identifiable {
    case still = "still"
    case autoScroll = "autoScroll"
    case spatialFixed = "spatialFixed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .still: return "静止"
        case .autoScroll: return "自動スクロール"
        case .spatialFixed: return "空間固定"
        }
    }

    var systemImage: String {
        switch self {
        case .still: return "textformat"
        case .autoScroll: return "arrow.right.to.line"
        case .spatialFixed: return "move.3d"
        }
    }
}
