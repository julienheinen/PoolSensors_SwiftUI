//
//  HistoryChartsView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 07/01/2026.
//

import SwiftUI

struct HistoryChartsView: View {
    let history: [PoolSensorData]

    private let maxPoints = 60

    var body: some View {
        let series = Array(history.sorted(by: { $0.timestamp < $1.timestamp }).suffix(maxPoints))

        if series.count < 2 {
            emptyState
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricChartCard(
                    title: "Température",
                    unit: "°C",
                    values: series.map { $0.temperature },
                    thresholds: (min: thresholds.temperatureMin, max: thresholds.temperatureMax),
                    valueFormat: "%.1f"
                )

                MetricChartCard(
                    title: "pH",
                    unit: "",
                    values: series.map { $0.ph },
                    thresholds: (min: thresholds.phMin, max: thresholds.phMax),
                    valueFormat: "%.2f"
                )

                MetricChartCard(
                    title: "Chlore",
                    unit: "mg/L",
                    values: series.map { $0.chlorine },
                    thresholds: (min: thresholds.chlorineMin, max: thresholds.chlorineMax),
                    valueFormat: "%.2f"
                )

                MetricChartCard(
                    title: "ORP",
                    unit: "mV",
                    values: series.map { $0.orp },
                    thresholds: (min: thresholds.orpMin, max: thresholds.orpMax),
                    valueFormat: "%.0f"
                )
            }
            .padding(.horizontal)
        }
    }

    private var thresholds: NotificationThresholds {
        NotificationThresholds.load()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 34))
                .foregroundColor(.secondary)

            Text("Pas assez d'historique")
                .font(.headline)

            Text("Les graphiques apparaissent après quelques mesures.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
}

private struct MetricChartCard: View {
    let title: String
    let unit: String
    let values: [Double]
    let thresholds: (min: Double, max: Double)
    let valueFormat: String

    var body: some View {
        let current = values.last ?? 0
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let isOutOfRange = current < thresholds.min || current > thresholds.max
        let lineColor: Color = isOutOfRange ? .orange : .green

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer(minLength: 8)

                Text(formatted(current))
                    .font(.headline)
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            MiniLineChart(values: values, lineColor: lineColor)

            HStack {
                Text("min \(formatted(minValue))")
                Spacer()
                Text("max \(formatted(maxValue))")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    private func formatted(_ value: Double) -> String {
        String(format: valueFormat, value)
    }
}

#Preview {
    HistoryChartsView(history: [
        PoolSensorData(timestamp: Date().addingTimeInterval(-300), temperature: 24.0, ph: 7.22, chlorine: 1.4, orp: 690),
        PoolSensorData(timestamp: Date().addingTimeInterval(-240), temperature: 24.1, ph: 7.25, chlorine: 1.6, orp: 700),
        PoolSensorData(timestamp: Date().addingTimeInterval(-180), temperature: 24.2, ph: 7.28, chlorine: 1.8, orp: 710),
        PoolSensorData(timestamp: Date().addingTimeInterval(-120), temperature: 24.3, ph: 7.30, chlorine: 2.0, orp: 720),
        PoolSensorData(timestamp: Date().addingTimeInterval(-60), temperature: 24.4, ph: 7.29, chlorine: 1.9, orp: 715),
    ])
    .padding()
}
