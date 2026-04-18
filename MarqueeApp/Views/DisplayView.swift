import SwiftUI

struct DisplayView: View {
    let settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @State private var controlsVisible = false

    var body: some View {
        ZStack {
            settings.bgColor.ignoresSafeArea()

            Group {
                switch settings.mode {
                case .still, .autoScroll:
                    MarqueeCanvasView(settings: settings)
                case .spatialFixed:
                    SpatialMarqueeView(settings: settings)
                }
            }
            .ignoresSafeArea()

            // Tap to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { controlsVisible.toggle() } }

            if controlsVisible {
                controlBar
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var controlBar: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title2.bold())
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                Text(settings.mode.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                // placeholder for symmetry
                Image(systemName: "chevron.down").opacity(0).padding(10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            Spacer()
        }
        .transition(.opacity)
    }
}
