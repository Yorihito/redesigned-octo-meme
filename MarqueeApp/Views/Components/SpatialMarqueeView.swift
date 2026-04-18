import SwiftUI

// Renders the dot matrix for spatial-fixed mode, offsetting with device motion.
struct SpatialMarqueeView: View {
    let settings: DisplaySettings
    @State private var motionService = MotionService()
    @State private var matrix: DotMatrix = .empty

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

                // Convert attitude offsets to pixel offsets.
                // sensitivity=1 means π/2 radians ≈ half content width shift.
                let scale = settings.spatialSensitivity * (contentW / (.pi / 2))
                let pitchScale = settings.spatialSensitivity * (contentH / (.pi / 2))

                let rawX = CGFloat(motionService.yawOffset) * scale
                let rawY = CGFloat(motionService.pitchOffset) * pitchScale

                // Clamp so the content doesn't scroll completely off screen
                let maxX = max(0, contentW - size.width)
                let maxY = max(0, contentH - size.height)
                let clampedX = max(-size.width / 2, min(maxX + size.width / 2, rawX))
                let clampedY = max(-size.height / 2, min(maxY + size.height / 2, rawY))

                let x = (size.width - contentW) / 2 - clampedX
                let y = (size.height - contentH) / 2 - clampedY

                renderer.draw(in: &ctx, offset: CGPoint(x: x, y: y))
            }
            .background(settings.bgColor)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    motionService.resetReference()
                } label: {
                    Image(systemName: "scope")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding()
            }
            .onAppear {
                rebuildMatrix()
                motionService.start()
            }
            .onDisappear {
                motionService.stop()
            }
            .onChange(of: settings.text) { _, _ in rebuildMatrix() }
            .onChange(of: settings.dotSize) { _, _ in rebuildMatrix() }
        }
    }

    private func rebuildMatrix() {
        let rows = max(7, Int(settings.glyphHeight / settings.dotSize))
        matrix = BitmapFont.matrix(for: settings.text, glyphRows: rows)
    }
}
