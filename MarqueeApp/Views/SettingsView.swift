import SwiftUI

struct SettingsView: View {
    @Bindable var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Dot size
                Section("ドットサイズ") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("サイズ")
                            Spacer()
                            Text("\(Int(settings.dotSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.dotSize, in: 4...24, step: 1)
                            .tint(settings.fgColor)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("ドット間隔")
                            Spacer()
                            Text(String(format: "%.1f pt", settings.dotSpacing))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.dotSpacing, in: 0.5...4, step: 0.5)
                            .tint(settings.fgColor)
                    }
                }

                // Colors
                Section("カラー") {
                    Picker("文字色", selection: $settings.foregroundColor) {
                        ForEach(LEDColor.allCases.filter { $0 != .black }) { color in
                            HStack {
                                Circle().fill(color.color).frame(width: 12, height: 12)
                                Text(color.label)
                            }.tag(color)
                        }
                    }
                    Picker("背景色", selection: $settings.backgroundColor) {
                        ForEach([LEDColor.black, .white]) { color in
                            Text(color.label).tag(color)
                        }
                    }
                }

                // Auto scroll
                Section("自動スクロール") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("スクロール速度")
                            Spacer()
                            Text("\(Int(settings.scrollSpeed)) pt/s")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.scrollSpeed, in: 20...200, step: 10)
                            .tint(settings.fgColor)
                    }
                    Toggle("ループ再生", isOn: $settings.loopEnabled)
                    if settings.loopEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("ループ待機時間")
                                Spacer()
                                Text(String(format: "%.1f 秒", settings.loopGapSeconds))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $settings.loopGapSeconds, in: 0...5, step: 0.5)
                                .tint(settings.fgColor)
                        }
                    }
                }

                // Spatial
                Section("空間固定モード") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("感度")
                            Spacer()
                            Text(String(format: "%.1fx", settings.spatialSensitivity))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.spatialSensitivity, in: 0.3...3.0, step: 0.1)
                            .tint(settings.fgColor)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}
