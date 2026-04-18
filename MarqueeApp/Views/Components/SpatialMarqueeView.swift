import SwiftUI

struct SpatialMarqueeView: View {
    let settings: DisplaySettings
    @State private var motion = MotionService()
    @State private var matrix: DotMatrix = .empty

    var body: some View {
        // Access motion properties HERE so @Observable tracks them and re-renders Canvas
        let yaw   = motion.yawOffset
        let pitch = motion.pitchOffset

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

            // Base center position
            let baseX = max(0, (size.width  - cw) / 2)
            let baseY = max(0, (size.height - ch) / 2)

            // Motion offset: sensitivity=1 → π/2 rad ≈ contentSize/2 shift
            let xShift = CGFloat(yaw)   * settings.spatialSensitivity * cw / (.pi / 2)
            let yShift = CGFloat(pitch) * settings.spatialSensitivity * ch / (.pi / 2)

            // Clamp so content never scrolls more than one screen away
            let clampedX = max(-(cw - size.width  + size.width  / 2),
                               min(size.width  / 2, xShift))
            let clampedY = max(-(ch - size.height + size.height / 2),
                               min(size.height / 2, yShift))

            r.draw(in: &ctx, offset: CGPoint(x: baseX - clampedX, y: baseY - clampedY))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.bgColor)
        .overlay(alignment: .bottomTrailing) {
            Button { motion.resetReference() } label: {
                Image(systemName: "scope")
                    .font(.title2)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
        .onAppear {
            rebuildMatrix()
            motion.start()
        }
        .onDisappear { motion.stop() }
        .onChange(of: settings.text)    { _, _ in rebuildMatrix() }
        .onChange(of: settings.dotSize) { _, _ in rebuildMatrix() }
    }

    private func rebuildMatrix() {
        let hasNonAscii = settings.text.unicodeScalars.contains { $0.value > 0x7E }
        matrix = BitmapFont.matrix(for: settings.text, glyphRows: hasNonAscii ? 16 : 7)
    }
}
