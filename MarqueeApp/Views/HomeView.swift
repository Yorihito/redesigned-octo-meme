import SwiftUI

struct HomeView: View {
    @State private var settings = DisplaySettings()
    @State private var showDisplay = false
    @State private var showSettings = false
    @FocusState private var textFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Preview
                    previewArea

                    // Mode selector
                    modeSelector

                    // Text input
                    textInputArea

                    // Display button
                    Button {
                        textFocused = false
                        showDisplay = true
                    } label: {
                        Label("表示開始", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(settings.fgColor)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(settings.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("MarqueeApp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(settings.fgColor)
                    }
                }
            }
            .fullScreenCover(isPresented: $showDisplay) {
                DisplayView(settings: settings)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sub-views

    private var previewArea: some View {
        ZStack {
            Color(white: 0.06)
            if settings.text.isEmpty {
                Text("文字を入力してください")
                    .foregroundStyle(.gray)
                    .font(.caption)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    MarqueeCanvasView(settings: previewSettings)
                        .frame(height: 60)
                        .padding(.horizontal, 8)
                }
            }
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private var modeSelector: some View {
        Picker("モード", selection: $settings.mode) {
            ForEach(DisplayMode.allCases) { mode in
                Label(mode.label, systemImage: mode.systemImage).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .tint(settings.fgColor)
    }

    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("表示テキスト")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)

            TextEditor(text: $settings.text)
                .focused($textFocused)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .background(Color(white: 0.1))
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }

    // Preview uses still mode at reduced dot size
    private var previewSettings: DisplaySettings {
        let s = DisplaySettings()
        s.text = settings.text
        s.mode = .still
        s.dotSize = 4
        s.dotSpacing = 0.8
        s.foregroundColor = settings.foregroundColor
        s.backgroundColor = settings.backgroundColor
        return s
    }
}
