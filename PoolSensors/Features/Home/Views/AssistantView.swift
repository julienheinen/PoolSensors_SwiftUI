//
//  AssistantView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 07/01/2026.
//

import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var showHistory = false

    var body: some View {
        NavigationView {
            ScrollView {
                let advice = PoolAssistantEngine.generateAdvice(from: viewModel.sensorData)

                VStack(alignment: .leading, spacing: 16) {
                    poolStatusCard(advice.poolStatus)

                    if advice.actions.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(advice.actions) { action in
                                actionCard(action)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 34, height: 34)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .accessibilityLabel("Historique")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
                    .environmentObject(viewModel)
            }
        }
    }

    private func header(_ advice: PoolAssistantAdvice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(advice.summary)
                .font(.headline)

            if let first = advice.insights.first {
                Text(first)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func poolStatusCard(_ status: PoolAssistantPoolStatus) -> some View {
        let statusColor = poolStatusColor(for: status.severity)
        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 54, height: 54)
                Image(systemName: status.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                    .font(.headline)

                Text(status.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func poolStatusColor(for severity: PoolAssistantAction.Severity) -> Color {
        switch severity {
        case .info:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aucune action")
                .font(.headline)

            Text("Ajoutez des mesures (MQTT) pour recevoir des recommandations basées sur les 5 dernières valeurs.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func actionCard(_ action: PoolAssistantAction) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: action.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color(for: action.severity))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.headline)

                Text(action.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func color(for severity: PoolAssistantAction.Severity) -> Color {
        switch severity {
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

#Preview {
    AssistantView()
        .environmentObject(AppViewModel())
}
