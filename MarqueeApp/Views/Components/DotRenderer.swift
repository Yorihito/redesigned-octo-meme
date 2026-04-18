import SwiftUI

struct DotRenderer {
    let matrix: DotMatrix
    let dotSize: CGFloat
    let spacing: CGFloat
    let fgColor: Color
    let bgColor: Color

    var totalWidth: CGFloat {
        CGFloat(matrix.cols) * (dotSize + spacing) - spacing
    }

    var totalHeight: CGFloat {
        CGFloat(matrix.rows) * (dotSize + spacing) - spacing
    }

    func draw(in context: inout GraphicsContext, offset: CGPoint = .zero) {
        let dimColor = fgColor.opacity(0.12)

        for row in 0..<matrix.rows {
            for col in 0..<matrix.cols {
                let x = offset.x + CGFloat(col) * (dotSize + spacing)
                let y = offset.y + CGFloat(row) * (dotSize + spacing)
                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                let path = Path(ellipseIn: rect)
                context.fill(path, with: .color(matrix.dot(row: row, col: col) ? fgColor : dimColor))
            }
        }
    }
}
