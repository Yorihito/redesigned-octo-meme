import UIKit
import CoreText

struct DotMatrix {
    let cols: Int
    let rows: Int
    private let data: [Bool]  // row-major, data[row*cols + col]

    init(cols: Int, rows: Int, data: [[Bool]]) {
        self.cols = cols
        self.rows = rows
        self.data = data.flatMap { $0 }
    }

    init(cols: Int, rows: Int, flat: [Bool]) {
        self.cols = cols
        self.rows = rows
        self.data = flat
    }

    func dot(row: Int, col: Int) -> Bool {
        guard row >= 0, row < rows, col >= 0, col < cols else { return false }
        return data[row * cols + col]
    }

    static let empty = DotMatrix(cols: 0, rows: 0, flat: [])
}

enum BitmapFont {
    // Build a DotMatrix for the given text.
    // glyphRows: number of dot rows per character line (default 16 for good Japanese quality)
    static func matrix(for text: String, glyphRows: Int = 16) -> DotMatrix {
        let lines = text.components(separatedBy: "\n")
        let lineMatrices = lines.map { lineDotMatrix(for: $0, glyphRows: glyphRows) }
        return stack(lineMatrices, rowSpacing: max(1, glyphRows / 8))
    }

    // Build a single-line DotMatrix
    static func lineDotMatrix(for line: String, glyphRows: Int) -> DotMatrix {
        guard !line.isEmpty else {
            return DotMatrix(cols: max(1, glyphRows / 2), rows: glyphRows, flat: Array(repeating: false, count: glyphRows / 2 * glyphRows))
        }
        let glyphs = line.map { rasterize($0, rows: glyphRows) }
        let colSpacing = max(1, glyphRows / 8)
        return concatenate(glyphs, colSpacing: colSpacing)
    }

    // Concatenate matrices horizontally
    private static func concatenate(_ matrices: [DotMatrix], colSpacing: Int) -> DotMatrix {
        guard !matrices.isEmpty else { return .empty }
        let rows = matrices[0].rows
        let totalCols = matrices.reduce(0) { $0 + $1.cols } + colSpacing * max(0, matrices.count - 1)
        var flat = [Bool](repeating: false, count: totalCols * rows)
        var xOff = 0
        for (i, m) in matrices.enumerated() {
            for r in 0..<rows {
                for c in 0..<m.cols {
                    flat[r * totalCols + xOff + c] = m.dot(row: r, col: c)
                }
            }
            xOff += m.cols + (i < matrices.count - 1 ? colSpacing : 0)
        }
        return DotMatrix(cols: totalCols, rows: rows, flat: flat)
    }

    // Stack matrices vertically
    private static func stack(_ matrices: [DotMatrix], rowSpacing: Int) -> DotMatrix {
        guard !matrices.isEmpty else { return .empty }
        let maxCols = matrices.map(\.cols).max() ?? 0
        let totalRows = matrices.reduce(0) { $0 + $1.rows } + rowSpacing * max(0, matrices.count - 1)
        var flat = [Bool](repeating: false, count: maxCols * totalRows)
        var yOff = 0
        for (i, m) in matrices.enumerated() {
            let xOff = (maxCols - m.cols) / 2  // center each line
            for r in 0..<m.rows {
                for c in 0..<m.cols {
                    if m.dot(row: r, col: c) {
                        flat[(yOff + r) * maxCols + xOff + c] = true
                    }
                }
            }
            yOff += m.rows + (i < matrices.count - 1 ? rowSpacing : 0)
        }
        return DotMatrix(cols: maxCols, rows: totalRows, flat: flat)
    }

    // Rasterize a single character to a DotMatrix using UIKit
    private static func rasterize(_ char: Character, rows: Int) -> DotMatrix {
        let cols = glyphCols(for: char, rows: rows)
        let size = CGSize(width: cols, height: rows)

        // Render at 4× for better quality, then downsample
        let scale = 4
        let bigSize = CGSize(width: cols * scale, height: rows * scale)
        let renderer = UIGraphicsImageRenderer(size: bigSize)
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: bigSize))
            let fontSize = CGFloat(rows * scale) * 0.85
            let font: UIFont
            if isFullWidthChar(char) {
                font = UIFont(name: "HiraginoSans-W3", size: fontSize)
                    ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
            } else {
                font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            }
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            let str = NSAttributedString(string: String(char), attributes: attrs)
            let textSize = str.size()
            let origin = CGPoint(
                x: (bigSize.width - textSize.width) / 2,
                y: (bigSize.height - textSize.height) / 2
            )
            str.draw(at: origin)
        }

        guard let cgImage = image.cgImage else { return emptyMatrix(cols: cols, rows: rows) }

        // Downsample to target size
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixelData = [UInt8](repeating: 0, count: cols * rows)
        guard let ctx = CGContext(
            data: &pixelData,
            width: cols,
            height: rows,
            bitsPerComponent: 8,
            bytesPerRow: cols,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return emptyMatrix(cols: cols, rows: rows) }
        ctx.interpolationQuality = .none
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))

        // Convert to Bool array (flipping Y: CGContext has bottom-left origin)
        var flat = [Bool](repeating: false, count: cols * rows)
        for r in 0..<rows {
            for c in 0..<cols {
                let cgRow = rows - 1 - r
                flat[r * cols + c] = pixelData[cgRow * cols + c] > 64
            }
        }
        return DotMatrix(cols: cols, rows: rows, flat: flat)
    }

    private static func emptyMatrix(cols: Int, rows: Int) -> DotMatrix {
        DotMatrix(cols: cols, rows: rows, flat: [Bool](repeating: false, count: cols * rows))
    }

    private static func glyphCols(for char: Character, rows: Int) -> Int {
        if isFullWidthChar(char) {
            return rows
        }
        return max(1, Int(round(Double(rows) * 5.0 / 9.0)))
    }

    private static func isFullWidthChar(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let v = scalar.value
        return (v >= 0x3000 && v <= 0x9FFF)   // CJK + hiragana + katakana
            || (v >= 0xF900 && v <= 0xFAFF)   // CJK compatibility
            || (v >= 0xFF00 && v <= 0xFFEF)   // Full-width forms
            || (v >= 0x1F300 && v <= 0x1FAFF) // Emoji (treated as square)
    }
}
