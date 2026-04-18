import UIKit

struct DotMatrix {
    let cols: Int
    let rows: Int
    private let data: [Bool]

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

    // MARK: - Public API

    static func matrix(for text: String, glyphRows: Int = 7) -> DotMatrix {
        let lines = text.components(separatedBy: "\n")
        let rowSpacing = max(1, glyphRows / 7)
        let lineMatrices = lines.map { lineDotMatrix(for: $0, glyphRows: glyphRows) }
        return stack(lineMatrices, rowSpacing: rowSpacing)
    }

    static func lineDotMatrix(for line: String, glyphRows: Int) -> DotMatrix {
        if line.isEmpty {
            let w = max(2, glyphRows / 2)
            return DotMatrix(cols: w, rows: glyphRows, flat: [Bool](repeating: false, count: w * glyphRows))
        }
        let colSpacing = max(1, glyphRows / 7)
        let glyphs = line.map { glyph(for: $0, rows: glyphRows) }
        return concatenate(glyphs, colSpacing: colSpacing)
    }

    // MARK: - Glyph dispatch

    private static func glyph(for char: Character, rows: Int) -> DotMatrix {
        if let scalar = char.unicodeScalars.first,
           scalar.value >= 0x20, scalar.value <= 0x7E {
            return asciiGlyph(for: char, targetRows: rows)
        }
        return rasterizeWithCoreText(char, rows: rows)
    }

    // MARK: - ASCII 5×7 bitmap font (Adafruit GFX, public domain)
    // Column-major: 5 bytes per glyph, bit 0 = top row (row 0), bit 6 = bottom row (row 6)

    // swiftlint:disable line_length
    private static let asciiColData: [[UInt8]] = [
        [0x00,0x00,0x00,0x00,0x00], // 0x20 ' '
        [0x00,0x00,0x5F,0x00,0x00], // 0x21 '!'
        [0x00,0x07,0x00,0x07,0x00], // 0x22 '"'
        [0x14,0x7F,0x14,0x7F,0x14], // 0x23 '#'
        [0x24,0x2A,0x7F,0x2A,0x12], // 0x24 '$'
        [0x23,0x13,0x08,0x64,0x62], // 0x25 '%'
        [0x36,0x49,0x55,0x22,0x50], // 0x26 '&'
        [0x00,0x05,0x03,0x00,0x00], // 0x27 '\''
        [0x00,0x1C,0x22,0x41,0x00], // 0x28 '('
        [0x00,0x41,0x22,0x1C,0x00], // 0x29 ')'
        [0x14,0x08,0x3E,0x08,0x14], // 0x2A '*'
        [0x08,0x08,0x3E,0x08,0x08], // 0x2B '+'
        [0x00,0x50,0x30,0x00,0x00], // 0x2C ','
        [0x08,0x08,0x08,0x08,0x08], // 0x2D '-'
        [0x00,0x60,0x60,0x00,0x00], // 0x2E '.'
        [0x20,0x10,0x08,0x04,0x02], // 0x2F '/'
        [0x3E,0x51,0x49,0x45,0x3E], // 0x30 '0'
        [0x00,0x42,0x7F,0x40,0x00], // 0x31 '1'
        [0x42,0x61,0x51,0x49,0x46], // 0x32 '2'
        [0x21,0x41,0x45,0x4B,0x31], // 0x33 '3'
        [0x18,0x14,0x12,0x7F,0x10], // 0x34 '4'
        [0x27,0x45,0x45,0x45,0x39], // 0x35 '5'
        [0x3C,0x4A,0x49,0x49,0x30], // 0x36 '6'
        [0x01,0x71,0x09,0x05,0x03], // 0x37 '7'
        [0x36,0x49,0x49,0x49,0x36], // 0x38 '8'
        [0x06,0x49,0x49,0x29,0x1E], // 0x39 '9'
        [0x00,0x36,0x36,0x00,0x00], // 0x3A ':'
        [0x00,0x56,0x36,0x00,0x00], // 0x3B ';'
        [0x08,0x14,0x22,0x41,0x00], // 0x3C '<'
        [0x14,0x14,0x14,0x14,0x14], // 0x3D '='
        [0x00,0x41,0x22,0x14,0x08], // 0x3E '>'
        [0x02,0x01,0x51,0x09,0x06], // 0x3F '?'
        [0x32,0x49,0x79,0x41,0x3E], // 0x40 '@'
        [0x7E,0x11,0x11,0x11,0x7E], // 0x41 'A'
        [0x7F,0x49,0x49,0x49,0x36], // 0x42 'B'
        [0x3E,0x41,0x41,0x41,0x22], // 0x43 'C'
        [0x7F,0x41,0x41,0x22,0x1C], // 0x44 'D'
        [0x7F,0x49,0x49,0x49,0x41], // 0x45 'E'
        [0x7F,0x09,0x09,0x09,0x01], // 0x46 'F'
        [0x3E,0x41,0x49,0x49,0x7A], // 0x47 'G'
        [0x7F,0x08,0x08,0x08,0x7F], // 0x48 'H'
        [0x00,0x41,0x7F,0x41,0x00], // 0x49 'I'
        [0x20,0x40,0x41,0x3F,0x01], // 0x4A 'J'
        [0x7F,0x08,0x14,0x22,0x41], // 0x4B 'K'
        [0x7F,0x40,0x40,0x40,0x40], // 0x4C 'L'
        [0x7F,0x02,0x0C,0x02,0x7F], // 0x4D 'M'
        [0x7F,0x04,0x08,0x10,0x7F], // 0x4E 'N'
        [0x3E,0x41,0x41,0x41,0x3E], // 0x4F 'O'
        [0x7F,0x09,0x09,0x09,0x06], // 0x50 'P'
        [0x3E,0x41,0x51,0x21,0x5E], // 0x51 'Q'
        [0x7F,0x09,0x19,0x29,0x46], // 0x52 'R'
        [0x46,0x49,0x49,0x49,0x31], // 0x53 'S'
        [0x01,0x01,0x7F,0x01,0x01], // 0x54 'T'
        [0x3F,0x40,0x40,0x40,0x3F], // 0x55 'U'
        [0x1F,0x20,0x40,0x20,0x1F], // 0x56 'V'
        [0x3F,0x40,0x38,0x40,0x3F], // 0x57 'W'
        [0x63,0x14,0x08,0x14,0x63], // 0x58 'X'
        [0x07,0x08,0x70,0x08,0x07], // 0x59 'Y'
        [0x61,0x51,0x49,0x45,0x43], // 0x5A 'Z'
        [0x00,0x7F,0x41,0x41,0x00], // 0x5B '['
        [0x02,0x04,0x08,0x10,0x20], // 0x5C '\'
        [0x00,0x41,0x41,0x7F,0x00], // 0x5D ']'
        [0x04,0x02,0x01,0x02,0x04], // 0x5E '^'
        [0x40,0x40,0x40,0x40,0x40], // 0x5F '_'
        [0x00,0x01,0x02,0x04,0x00], // 0x60 '`'
        [0x20,0x54,0x54,0x54,0x78], // 0x61 'a'
        [0x7F,0x48,0x44,0x44,0x38], // 0x62 'b'
        [0x38,0x44,0x44,0x44,0x20], // 0x63 'c'
        [0x38,0x44,0x44,0x48,0x7F], // 0x64 'd'
        [0x38,0x54,0x54,0x54,0x18], // 0x65 'e'
        [0x08,0x7E,0x09,0x01,0x02], // 0x66 'f'
        [0x0C,0x52,0x52,0x52,0x3E], // 0x67 'g'
        [0x7F,0x08,0x04,0x04,0x78], // 0x68 'h'
        [0x00,0x44,0x7D,0x40,0x00], // 0x69 'i'
        [0x20,0x40,0x44,0x3D,0x00], // 0x6A 'j'
        [0x7F,0x10,0x28,0x44,0x00], // 0x6B 'k'
        [0x00,0x41,0x7F,0x40,0x00], // 0x6C 'l'
        [0x7C,0x04,0x18,0x04,0x78], // 0x6D 'm'
        [0x7C,0x08,0x04,0x04,0x78], // 0x6E 'n'
        [0x38,0x44,0x44,0x44,0x38], // 0x6F 'o'
        [0x7C,0x14,0x14,0x14,0x08], // 0x70 'p'
        [0x08,0x14,0x14,0x18,0x7C], // 0x71 'q'
        [0x7C,0x08,0x04,0x04,0x08], // 0x72 'r'
        [0x48,0x54,0x54,0x54,0x20], // 0x73 's'
        [0x04,0x3F,0x44,0x40,0x20], // 0x74 't'
        [0x3C,0x40,0x40,0x20,0x7C], // 0x75 'u'
        [0x1C,0x20,0x40,0x20,0x1C], // 0x76 'v'
        [0x3C,0x40,0x30,0x40,0x3C], // 0x77 'w'
        [0x44,0x28,0x10,0x28,0x44], // 0x78 'x'
        [0x0C,0x50,0x50,0x50,0x3C], // 0x79 'y'
        [0x44,0x64,0x54,0x4C,0x44], // 0x7A 'z'
        [0x00,0x08,0x36,0x41,0x00], // 0x7B '{'
        [0x00,0x00,0x7F,0x00,0x00], // 0x7C '|'
        [0x00,0x41,0x36,0x08,0x00], // 0x7D '}'
        [0x10,0x08,0x08,0x10,0x08], // 0x7E '~'
    ]
    // swiftlint:enable line_length

    // Resolve ASCII glyph from bitmap data, scaled to targetRows if > 7
    private static func asciiGlyph(for char: Character, targetRows: Int) -> DotMatrix {
        guard let scalar = char.unicodeScalars.first,
              scalar.value >= 0x20, scalar.value <= 0x7E else {
            return emptyMatrix(cols: 5, rows: targetRows)
        }
        let cols = asciiColData[Int(scalar.value - 0x20)]
        // Build 5×7 matrix from column data
        var flat7 = [Bool](repeating: false, count: 5 * 7)
        for c in 0..<5 {
            let byte = cols[c]
            for r in 0..<7 {
                flat7[r * 5 + c] = (byte >> r) & 1 == 1
            }
        }
        let base = DotMatrix(cols: 5, rows: 7, flat: flat7)
        guard targetRows > 7 else { return base }
        // Scale up by nearest-neighbor when targetRows > 7
        return scale(base, toRows: targetRows)
    }

    // Scale a DotMatrix to a new row count (keeps aspect ratio)
    private static func scale(_ m: DotMatrix, toRows targetRows: Int) -> DotMatrix {
        let scaleY = Double(targetRows) / Double(m.rows)
        let targetCols = max(1, Int(round(Double(m.cols) * scaleY)))
        var flat = [Bool](repeating: false, count: targetCols * targetRows)
        for r in 0..<targetRows {
            let srcR = Int(Double(r) / scaleY)
            for c in 0..<targetCols {
                let srcC = Int(Double(c) / scaleY)
                flat[r * targetCols + c] = m.dot(row: srcR, col: srcC)
            }
        }
        return DotMatrix(cols: targetCols, rows: targetRows, flat: flat)
    }

    // MARK: - CoreText fallback for non-ASCII (Japanese, emoji, etc.)
    // Renders at targetRows * oversample pixels for quality, then thresholds

    private static let coreTextOversample = 8

    private static func rasterizeWithCoreText(_ char: Character, rows: Int) -> DotMatrix {
        let isWide = isFullWidthChar(char)
        let cols = isWide ? rows : max(1, Int(round(Double(rows) * 0.7)))

        let os = coreTextOversample
        let pw = cols * os   // pixel width
        let ph = rows * os   // pixel height
        let fontSize = CGFloat(ph) * 0.85

        // Render white text on black at os× resolution
        let font: UIFont = UIFont(name: "HiraginoSans-W3", size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
        let str = NSAttributedString(string: String(char), attributes: attrs)
        let textSize = str.size()

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: pw * ph)
        guard let ctx = CGContext(
            data: &pixels, width: pw, height: ph,
            bitsPerComponent: 8, bytesPerRow: pw,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return emptyMatrix(cols: cols, rows: rows) }

        UIGraphicsPushContext(ctx)
        let ox = (CGFloat(pw) - textSize.width) / 2
        // Adjust for descender so glyph sits in the middle vertically
        let descender = font.descender
        let oy = (CGFloat(ph) - textSize.height) / 2 - descender
        str.draw(at: CGPoint(x: ox, y: oy))
        UIGraphicsPopContext()

        // Average os×os pixel blocks to get `cols × rows` result
        var flat = [Bool](repeating: false, count: cols * rows)
        for r in 0..<rows {
            let py0 = r * os
            for c in 0..<cols {
                let px0 = c * os
                var sum = 0
                for dy in 0..<os {
                    for dx in 0..<os {
                        // Flip Y: CGContext is bottom-left origin
                        let cgRow = ph - 1 - (py0 + dy)
                        sum += Int(pixels[cgRow * pw + px0 + dx])
                    }
                }
                flat[r * cols + c] = sum > (os * os * 255 / 4)  // threshold: 25% lit
            }
        }
        return DotMatrix(cols: cols, rows: rows, flat: flat)
    }

    // MARK: - Layout helpers

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

    private static func stack(_ matrices: [DotMatrix], rowSpacing: Int) -> DotMatrix {
        guard !matrices.isEmpty else { return .empty }
        let maxCols = matrices.map(\.cols).max() ?? 0
        let totalRows = matrices.reduce(0) { $0 + $1.rows } + rowSpacing * max(0, matrices.count - 1)
        var flat = [Bool](repeating: false, count: maxCols * totalRows)
        var yOff = 0
        for (i, m) in matrices.enumerated() {
            let xOff = (maxCols - m.cols) / 2
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

    private static func emptyMatrix(cols: Int, rows: Int) -> DotMatrix {
        DotMatrix(cols: cols, rows: rows, flat: [Bool](repeating: false, count: max(0, cols * rows)))
    }

    private static func isFullWidthChar(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let v = scalar.value
        return (v >= 0x3000 && v <= 0x9FFF)
            || (v >= 0xF900 && v <= 0xFAFF)
            || (v >= 0xFF00 && v <= 0xFFEF)
            || (v >= 0x1F300 && v <= 0x1FAFF)
    }
}
