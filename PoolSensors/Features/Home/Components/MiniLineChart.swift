//
//  MiniLineChart.swift
//  PoolSensors
//
//  Created by Julien Heinen on 07/01/2026.
//

import SwiftUI

struct MiniLineChart: View {
    let values: [Double]
    let lineColor: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = normalizedPoints(in: size)

            ZStack {
                if points.count >= 2 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    if let lastPoint = points.last {
                        Circle()
                            .fill(lineColor)
                            .frame(width: 6, height: 6)
                            .position(lastPoint)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                }
            }
        }
        .frame(height: 56)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = max(0.000_001, maxValue - minValue)

        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(Double(index) / Double(max(values.count - 1, 1)))
            let normalizedY = (value - minValue) / range
            let y = size.height * (1 - CGFloat(normalizedY))
            return CGPoint(x: x, y: y)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MiniLineChart(values: [7.1, 7.2, 7.25, 7.3, 7.28, 7.32], lineColor: .accentColor)
        MiniLineChart(values: [24, 24, 24, 24, 24, 24], lineColor: .accentColor)
    }
    .padding()
}
