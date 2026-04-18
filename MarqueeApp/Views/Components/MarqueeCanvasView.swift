import SwiftUI

struct MarqueeCanvasView: View {
    let settings: DisplaySettings
    @State private var matrix: DotMatrix = .empty
    @State private var scrollAnchor: Date = .now

    var body: some View {
        if settings.mode == .autoScroll {
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in
                dotCanvas(date: tl.date)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(settings.bgColor)
            .onAppear { rebuildMatrix(); scrollAnchor = .now }
            .onChange(of: settings.text)    { _, _ in rebuildMatrix(); scrollAnchor = .now }
            .onChange(of: settings.dotSize) { _, _ in rebuildMatrix(); scrollAnchor = .now }
        } else {
            dotCanvas(date: .now)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(settings.bgColor)
                .onAppear { rebuildMatrix() }
                .onChange(of: settings.text)    { _, _ in rebuildMatrix() }
                .onChange(of: settings.dotSize) { _, _ in rebuildMatrix() }
        }
    }

    // MARK: - Canvas

    private func dotCanvas(date: Date) -> some View {
        Canvas { ctx, size in
            let r = DotRenderer(
                matrix: matrix,
                dotSize: settings.dotSize,
                spacing: settings.dotSpacing,
                fgColor: settings.fgColor,
                bgColor: settings.bgColor
            )
            let cw = r.totalWidth
            let ch = r.totalHeight
            let x = xOffset(contentW: cw, viewW: size.width, date: date)
            let y = max(0, (size.height - ch) / 2)
            r.draw(in: &ctx, offset: CGPoint(x: x, y: y))
        }
    }

    // MARK: - Offset calculation

    private func xOffset(contentW: CGFloat, viewW: CGFloat, date: Date) -> CGFloat {
        switch settings.mode {
        case .still:
            // Center if fits; left-align if wider than screen
            return max(0, (viewW - contentW) / 2)

        case .autoScroll:
            // Text enters from right (x=viewW) and exits left (x=-contentW)
            let totalDist = contentW + viewW
            guard totalDist > 0, settings.scrollSpeed > 0 else { return viewW }
            let scrollDuration = Double(totalDist) / settings.scrollSpeed
            let cycleDuration  = scrollDuration + (settings.loopEnabled ? settings.loopGapSeconds : 0)
            let elapsed = date.timeIntervalSince(scrollAnchor)
            let phase   = cycleDuration > 0
                ? elapsed.truncatingRemainder(dividingBy: cycleDuration)
                : elapsed
            let scrolled = CGFloat(min(phase, scrollDuration) * settings.scrollSpeed)
            return viewW - scrolled

        case .spatialFixed:
            return max(0, (viewW - contentW) / 2)
        }
    }

    // MARK: - Matrix build

    private func rebuildMatrix() {
        let hasNonAscii = settings.text.unicodeScalars.contains { $0.value > 0x7E }
        matrix = BitmapFont.matrix(for: settings.text, glyphRows: hasNonAscii ? 16 : 7)
    }
}
