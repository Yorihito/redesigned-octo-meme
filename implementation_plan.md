# インプリメンテーションプラン：電光掲示板風iPhoneアプリ

本ドキュメントは [requirements.md](requirements.md) に基づいた実装計画である。

---

## 1. 技術選定

### 1.1 プラットフォーム・言語
| 項目 | 採用 | 理由 |
|---|---|---|
| 言語 | Swift 5.9+ | iOSネイティブ標準 |
| 最低iOSバージョン | iOS 16.0 | SwiftUIの成熟度と普及率のバランス |
| UIフレームワーク | SwiftUI（一部 UIKit） | 宣言的UI。描画パフォーマンスが必要な箇所のみ UIViewRepresentable で UIKit/Metal を橋渡し |
| アーキテクチャ | MVVM + Observation (@Observable) | SwiftUI公式の推奨形 |
| 最小対応機種 | iPhone XS 以降 | Core Motion のジャイロ/加速度センサーとA12 Bionic以上のGPU性能を確保 |

### 1.2 描画エンジン方針
電光掲示板フォントは「ドットの粒状感」が重要なため、以下の2段階で実装する：

- **フェーズ1（MVP）**: `Canvas` (SwiftUI) + `GraphicsContext` を用いたドット描画
  - 各文字のビットマップパターン（例：5x7ドット）を定義し、ドットを円/矩形として描画
  - 実装容易で、60fps描画が可能な見込み
- **フェーズ2（最適化）**: 必要に応じて Metal でのGPU描画に移行
  - 長文スクロールで処理落ちする場合に検討
  - ドット描画をインスタンシングで高速化

### 1.3 モーション検出方式
**採用: Core Motion（デバイスモーション、attitude + userAcceleration）**

理由：
- ARKitは過剰性能（空間認識や平面検出は不要）
- バッテリー消費・CPU負荷が小さい
- カメラ権限が不要でUX上シンプル
- 姿勢（attitude）のロール/ピッチ/ヨーで方向変化を取得し、加速度を二重積分して位置差分を推定
- ドリフト誤差は「リセット機能」で都度補正できる前提で実装

### 1.4 フォント
**採用: 自前のビットマップパターン定義（独自実装）**

理由：
- 一般的な電光掲示板フォントは5x7〜8x8ドットの固定幅が主流で、1文字ずつパターン配列として保持可能
- 既存フォント利用はライセンス問題が発生しうる
- 初期サポート文字範囲を限定（英数字・記号・基本カタカナ）し、段階的に拡張
- 日本語漢字対応は**フェーズ2以降**（パターンデータ量が大きいため、SF Proベース＋ドット化フィルタで代替する方針も検討）

---

## 2. 画面構成・UI設計

### 2.1 画面一覧
1. **ホーム画面**（テキスト入力 + モード選択）
2. **表示画面**（フルスクリーンで電光掲示板表示）
3. **設定画面**（文字サイズ、スクロール速度、色など）

### 2.2 モード切り替えUI
- ホーム画面下部にセグメントコントロール（静止 / 自動スクロール / 空間固定）
- モードごとに必要な設定項目を動的に表示
- 「表示開始」ボタンで表示画面へ遷移（フルスクリーン）

### 2.3 表示画面UI
- デフォルトは横向きフルスクリーン、UIは非表示
- タップで最小限のコントロールバー表示（戻る、リセット、一時停止）
- 背景は黒、文字はオレンジ（LED風）をデフォルト

---

## 3. モジュール構成

```
MarqueeApp/
├── App/
│   └── MarqueeAppApp.swift              # エントリポイント
├── Models/
│   ├── DisplayMode.swift                # 表示モード enum
│   ├── DisplaySettings.swift            # ユーザー設定（@Observable）
│   └── BitmapFont.swift                 # ビットマップフォントデータ
├── Views/
│   ├── HomeView.swift                   # ホーム画面
│   ├── DisplayView.swift                # 表示画面（モードで分岐）
│   ├── SettingsView.swift               # 設定画面
│   └── Components/
│       ├── MarqueeCanvasView.swift      # 静止/自動スクロール描画
│       ├── SpatialMarqueeView.swift     # 空間固定モード描画
│       └── DotRenderer.swift            # ドット描画ロジック
├── ViewModels/
│   ├── DisplayViewModel.swift
│   └── MotionViewModel.swift            # Core Motion ラッパー
├── Services/
│   ├── MotionService.swift              # CMMotionManager 管理
│   └── SettingsStore.swift              # UserDefaults永続化
└── Resources/
    └── BitmapFontData/                  # フォントパターン定義（JSON or Swift）
```

---

## 4. 実装フェーズ

### フェーズ0: プロジェクトセットアップ（0.5日）
- [ ] Xcodeプロジェクト作成（SwiftUI, iOS 16+）
- [ ] Git初期化、`.gitignore`設定
- [ ] ディレクトリ構造作成
- [ ] Info.plist にモーション使用目的文言を追加（`NSMotionUsageDescription`）
- [ ] 基本的なカラー/フォントアセット登録

### フェーズ1: ビットマップフォント描画基盤（2-3日）
**目標**: 任意の文字列を電光掲示板風ドットで描画できる状態

- [ ] 5x7ドットのビットマップフォントパターン定義（英数字・記号・スペース、約95文字）
- [ ] `DotRenderer`: 文字列 → ドット配列への変換ロジック
- [ ] `Canvas` ベースの描画実装
  - ドットサイズ、間隔、色を引数化
  - オン/オフドット両方の描画（背景ドットも薄く表示することでリアル感を出す）
- [ ] 静止表示の動作確認（プレビュー）
- [ ] 単体テスト：文字 → ドット配列変換

### フェーズ2: 静止表示モード（1日）
- [ ] `HomeView` のテキスト入力UI
- [ ] `DisplayView` で静止表示モード実装
- [ ] 文字サイズ設定UIとリアルタイムプレビュー
- [ ] 文字が画面幅を超える場合の改行処理（またはトリミング）
- [ ] 複数行入力の対応

### フェーズ3: 自動スクロールモード（1-2日）
- [ ] `TimelineView` を用いた毎フレーム描画
- [ ] スクロールオフセット管理（時間ベースで算出）
- [ ] スクロール速度設定UI
- [ ] ループ再生 / 1回再生の切り替え
- [ ] ループ間の待機時間設定
- [ ] 60fps維持の確認（実機計測）

### フェーズ4: 空間固定モード（3-4日）
**最も難易度の高いフェーズ**

- [ ] `MotionService` 実装
  - `CMMotionManager.startDeviceMotionUpdates` で attitude + userAcceleration 取得
  - 60Hz以上でのサンプリング
- [ ] 姿勢角（ヨー/ピッチ）から画面オフセットへの変換
  - ヨー（左右首振り） → 横方向スクロール
  - ピッチ（上下首振り） → 縦方向スクロール
  - 画角と仮想表示領域のサイズから変換係数を算出
- [ ] 加速度ベースの平行移動検知（オプション、ノイズ多いため優先度低）
- [ ] リセット機能（現在姿勢を中心にする、quaternion基準点の保存）
- [ ] 仮想表示領域のレイアウト（全テキストを1つの大きなキャンバスに配置し、端末姿勢でビューポートを移動）
- [ ] キャリブレーション：動きに対するスクロール比率のユーザー調整

### フェーズ5: 設定・永続化（1日）
- [ ] `SettingsStore` による UserDefaults ラッパー
- [ ] 全設定項目の画面
  - 文字サイズ
  - スクロール速度
  - ループ設定
  - 色設定（LED色プリセット：オレンジ/赤/緑/白）
  - 空間固定モードの感度
- [ ] 入力履歴の保存（直近10件、任意）

### フェーズ6: 磨き込み・最適化（2-3日）
- [ ] 実機でのパフォーマンス測定（Instruments）
- [ ] バッテリー消費測定
- [ ] スクロール描画のジャンク対策
- [ ] 必要に応じた Metal 化の判断・実装
- [ ] 画面回転対応（縦・横）
- [ ] アクセシビリティ対応（VoiceOverで入力内容を読み上げ）
- [ ] アイコン・スプラッシュ画面作成

### フェーズ7: テスト・リリース準備（2日）
- [ ] 実機テスト（複数機種）
- [ ] TestFlight配信・ベータテスト
- [ ] App Store スクリーンショット・説明文準備
- [ ] プライバシーポリシー作成（モーションセンサー使用）
- [ ] App Store 審査提出

**合計見積もり工数: 約12-17日（1人開発想定）**

---

## 5. 主要クラス・インターフェース設計

### 5.1 DisplayMode
```swift
enum DisplayMode: String, CaseIterable, Identifiable {
    case still         // 静止表示
    case autoScroll    // 自動スクロール
    case spatialFixed  // 空間固定
    var id: String { rawValue }
}
```

### 5.2 DisplaySettings（@Observable）
```swift
@Observable
final class DisplaySettings {
    var text: String = ""
    var mode: DisplayMode = .still
    var dotSize: CGFloat = 8.0       // ドット1個のピクセルサイズ
    var dotSpacing: CGFloat = 1.0
    var scrollSpeed: Double = 60.0   // pt/sec
    var loopEnabled: Bool = true
    var loopGap: Double = 1.0        // 秒
    var foregroundColor: Color = .orange
    var backgroundColor: Color = .black
    var spatialSensitivity: Double = 1.0
}
```

### 5.3 BitmapFont
```swift
struct BitmapFont {
    static let glyphWidth = 5
    static let glyphHeight = 7
    // Character → [[Bool]] (行×列のドットON/OFF)
    static func glyph(for character: Character) -> [[Bool]]
    // 文字列全体を一枚のドットマトリクスに変換（幅可変）
    static func bitmap(for text: String) -> DotMatrix
}

struct DotMatrix {
    let width: Int
    let height: Int
    let dots: [[Bool]]   // [row][col]
}
```

### 5.4 MotionService
```swift
@Observable
final class MotionService {
    private let manager = CMMotionManager()
    private(set) var yawOffset: Double = 0
    private(set) var pitchOffset: Double = 0
    private var referenceAttitude: CMAttitude?

    func start()
    func stop()
    func resetReference()  // 現在姿勢を原点にする
}
```

### 5.5 DotRenderer
```swift
struct DotRenderer {
    static func draw(
        matrix: DotMatrix,
        in context: GraphicsContext,
        offset: CGPoint,
        dotSize: CGFloat,
        spacing: CGFloat,
        fgColor: Color,
        bgColor: Color
    )
}
```

---

## 6. リスクと対策

| リスク | 影響 | 対策 |
|---|---|---|
| 空間固定モードのドリフト誤差 | 長時間使用で文字がずれる | リセットボタンを目立つ位置に配置。ユーザーに仕組みを説明 |
| Canvas描画の60fps未達 | 体験品質低下 | 早期にパフォーマンス計測し、閾値を超えたらMetal移行 |
| 漢字フォントのデータ量 | アプリサイズ増大 | 初期版では英数字・カナのみ。漢字はSF Proのドット化で暫定対応 |
| モーション感度の個人差 | 使い勝手のばらつき | キャリブレーションUIで調整可能に |
| 長文入力時のレイアウト崩れ | バグ報告増 | 文字数上限を設定（暫定500文字）し、段階的に緩和 |

---

## 7. 要件定義の未確定事項への対応方針

requirements.md 7章の未確定事項について、本プランでの暫定決定：

| # | 項目 | 暫定決定 |
|---|---|---|
| 1 | 文字列最大長 | 500文字（後続拡張可） |
| 2 | 文字サイズ範囲 | ドットサイズ 4pt〜24pt（8段階） |
| 3 | 文字色・背景色 | 色プリセット 4種（オレンジ/赤/緑/白） + 黒背景固定（フェーズ1） |
| 4 | スクロール速度 | 20〜200 pt/秒（スライダー） |
| 5 | 空間固定の実現方式 | Core Motion 採用 |
| 6 | iOS下限 | iOS 16.0 |
| 7 | 対応機種 | iPhone XS 以降 |
| 8 | 入力履歴 | 直近10件をUserDefaultsに保存 |
| 9 | モード切替UI | セグメントコントロール（ホーム画面） |
| 10 | 縦横対応 | フェーズ1は横向き推奨、フェーズ6で両対応 |

---

## 8. マイルストーン

| マイルストーン | 完了目安 | 成果物 |
|---|---|---|
| M1: 描画基盤動作 | フェーズ1終了時 | 任意文字列をドット表示できるデモ |
| M2: 2モード完成 | フェーズ3終了時 | 静止・自動スクロールの動作版 |
| M3: 全モード完成 | フェーズ4終了時 | 空間固定含む機能完成版 |
| M4: MVP完成 | フェーズ5終了時 | 設定機能含む内部リリース候補 |
| M5: リリース版 | フェーズ7終了時 | App Store審査提出 |

---

## 9. 次のアクション

1. 本プランのレビュー・承認
2. Xcodeプロジェクト作成とリポジトリ初期コミット
3. フェーズ1着手（ビットマップフォント描画基盤）
