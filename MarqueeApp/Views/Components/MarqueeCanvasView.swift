import SwiftUI

// Renders the dot matrix for still and auto-scroll modes.
struct MarqueeCanvasView: View {
    let settings: DisplaySettings
    @State private var scrollOffset: CGFloat = 0
    @State private var matrix: DotMatrix = .empty
    @State private var isScrolling = false

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let renderer = DotRenderer(
                    matrix: matrix,
                    dotSize: settings.dotSize,
                    spacing: settings.dotSpacing,
                    fgColor: settings.fgColor,
                    bgColor: settings.bgColor
                )
                let contentW = renderer.totalWidth
                let contentH = renderer.totalHeight
                let x = settings.mode == .still
                    ? (size.width - contentW) / 2
                    : -scrollOffset
                let y = (size.height - contentH) / 2
                renderer.draw(in: &ctx, offset: CGPoint(x: x, y: y))
            }
            .background(settings.bgColor)
            .onAppear {
                rebuildMatrix()
                if settings.mode == .autoScroll { startScroll(in: geo.size) }
            }
            .onChange(of: settings.text) { _, _ in
                rebuildMatrix()
                if settings.mode == .autoScroll { startScroll(in: geo.size) }
            }
            .onChange(of: settings.dotSize) { _, _ in rebuildMatrix() }
        }
    }

    private func rebuildMatrix() {
        let rows = max(7, Int(settings.glyphHeight / settings.dotSize))
        matrix = BitmapFont.matrix(for: settings.text, glyphRows: rows)
    }

    private func startScroll(in size: CGSize) {
        guard settings.mode == .autoScroll else { return }
        guard !isScrolling else { return }
        isScrolling = true
        scrollOffset = 0
        runScrollLoop(viewWidth: size.width)
    }

    private func runScrollLoop(viewWidth: CGFloat) {
        let renderer = DotRenderer(
            matrix: matrix, dotSize: settings.dotSize,
            spacing: settings.dotSpacing, fgColor: .clear, bgColor: .clear
        )
        let contentWidth = renderer.totalWidth
        guard contentWidth > viewWidth else {
            isScrolling = false
            return
        }
        let distance = contentWidth + viewWidth
        let duration = distance / settings.scrollSpeed

        withAnimation(.linear(duration: duration)) {
            scrollOffset = distance
        } completion: {
            scrollOffset = 0
            if settings.loopEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + settings.loopGapSeconds) {
                    runScrollLoop(viewWidth: viewWidth)
                }
            } else {
                isScrolling = false
            }
        }
    }
}
