//
//  PoolAssistantEngine.swift
//  PoolSensors
//
//  Created by Julien Heinen on 07/01/2026.
//

import Foundation

struct PoolAssistantAction: Identifiable {
    enum Severity {
        case info
        case warning
        case critical
    }

    let id = UUID()
    let systemImage: String
    let title: String
    let subtitle: String
    let severity: Severity
}

struct PoolAssistantAdvice {
    let title: String
    let summary: String
    let insights: [String]
    let poolStatus: PoolAssistantPoolStatus
    let actions: [PoolAssistantAction]
}

struct PoolAssistantPoolStatus {
    let systemImage: String
    let title: String
    let subtitle: String
    let severity: PoolAssistantAction.Severity
}

enum PoolAssistantEngine {
    static let minimumHistoryCount = 5
    private static let poolVolumeKey = "poolVolumeM3"
    private static let availableChlorinePercentKey = "availableChlorinePercent"
    private static let phPlusDoseKey = "phPlusDoseGPer10m3Per0_1"
    private static let phMinusDoseKey = "phMinusDoseGPer10m3Per0_1"

    static func generateAdvice(from history: [PoolSensorData]) -> PoolAssistantAdvice {
        guard history.count >= minimumHistoryCount else {
            return PoolAssistantAdvice(
                title: "Données insuffisantes",
                summary: "J'ai besoin d'au moins \\(minimumHistoryCount) mesures pour proposer des actions fiables.",
                insights: ["Mesures disponibles : \\(history.count)"],
                poolStatus: PoolAssistantPoolStatus(
                    systemImage: "water.waves",
                    title: "Données insuffisantes",
                    subtitle: "Ajoutez quelques mesures pour afficher l'état de la piscine.",
                    severity: .info
                ),
                actions: [
                    PoolAssistantAction(
                        systemImage: "clock.arrow.circlepath",
                        title: "Attendre plus de mesures",
                        subtitle: "Laissez tourner la filtration et revenez quand l'historique contient au moins \\(minimumHistoryCount) points.",
                        severity: .info
                    )
                ]
            )
        }

        let last = Array(history.suffix(minimumHistoryCount))
        let avgTemp = average(last.map { $0.temperature })
        let avgPh = average(last.map { $0.ph })
        let avgChlorine = average(last.map { $0.chlorine })
        let avgOrp = average(last.map { $0.orp })

        let tempTrend = trend(from: last.map { $0.temperature })
        let phTrend = trend(from: last.map { $0.ph })
        let chlorineTrend = trend(from: last.map { $0.chlorine })
        let orpTrend = trend(from: last.map { $0.orp })

        let thresholds = NotificationThresholds.load()
        let poolVolumeM3 = max(1.0, UserDefaults.standard.double(forKey: poolVolumeKey))
        let availableChlorinePercent = max(1.0, min(100.0, UserDefaults.standard.double(forKey: availableChlorinePercentKey)))
        let phPlusDose = defaultIfZero(UserDefaults.standard.double(forKey: phPlusDoseKey), defaultValue: 150) // g / 10m3 / +0.1
        let phMinusDose = defaultIfZero(UserDefaults.standard.double(forKey: phMinusDoseKey), defaultValue: 150) // g / 10m3 / -0.1

        var insights: [String] = []
        insights.append("Basé sur les \\(minimumHistoryCount) dernières mesures")

        let poolStatus = makePoolStatus(
            avgTemp: avgTemp,
            tempTrend: tempTrend,
            avgPh: avgPh,
            phTrend: phTrend,
            avgChlorine: avgChlorine,
            chlorineTrend: chlorineTrend,
            avgOrp: avgOrp,
            orpTrend: orpTrend,
            thresholds: thresholds
        )

        var actions: [PoolAssistantAction] = []
        func appendUnique(_ action: PoolAssistantAction) {
            if actions.contains(where: { $0.title == action.title }) { return }
            actions.append(action)
        }

        // Plan d'action : pH -> chlore -> filtration -> attente -> re-mesure
        let phTarget = 7.3
        let chlorineTarget = (thresholds.chlorineMin + thresholds.chlorineMax) / 2
        let recommendedFiltrationHours = filtrationHoursFor(tempC: avgTemp)

        var needsWait = false
        var waitHours: Double = 0

        let hasHighChlorine = avgChlorine > thresholds.chlorineMax

        // 1) pH
        if avgPh < thresholds.phMin {
            let delta = max(0, phTarget - avgPh)
            let grams = gramsForPhAdjustment(deltaPh: delta, volumeM3: poolVolumeM3, doseGPer10m3Per0_1: phPlusDose)
            appendUnique(
                PoolAssistantAction(
                    systemImage: "arrow.up.circle.fill",
                    title: "pH trop bas",
                    subtitle: String(format: "~%.0f g en 2-3 fois, devant le refoulement (objectif %.2f)", roundToNearest5(grams), phTarget),
                    severity: .warning
                )
            )
            needsWait = true
            waitHours = max(waitHours, 3)
        } else if avgPh > thresholds.phMax {
            let delta = max(0, avgPh - phTarget)
            let grams = gramsForPhAdjustment(deltaPh: delta, volumeM3: poolVolumeM3, doseGPer10m3Per0_1: phMinusDose)
            appendUnique(
                PoolAssistantAction(
                    systemImage: "arrow.down.circle.fill",
                    title: "pH trop haut",
                    subtitle: String(format: "~%.0f g en 2-3 fois, devant le refoulement (objectif %.2f). Le chlore agit moins bien si pH trop haut.", roundToNearest5(grams), phTarget),
                    severity: .warning
                )
            )
            needsWait = true
            waitHours = max(waitHours, 3)
        }

        // 2) Chlore
        if avgChlorine < thresholds.chlorineMin {
            let delta = max(0, chlorineTarget - avgChlorine)
            let grams = gramsOfChlorineProductToIncrease(
                deltaMgPerL: delta,
                volumeM3: poolVolumeM3,
                availableChlorinePercent: availableChlorinePercent
            )
            appendUnique(
                PoolAssistantAction(
                    systemImage: "plus.circle.fill",
                    title: "Chlore trop bas",
                    subtitle: String(format: "~%.0f g de produit, en 2 fois (objectif %.1f mg/L)", roundToNearest5(grams), chlorineTarget),
                    severity: .warning
                )
            )
            needsWait = true
            waitHours = max(waitHours, 4)
        } else if hasHighChlorine {
            appendUnique(
                PoolAssistantAction(
                    systemImage: "pause.circle.fill",
                    title: "Chlore trop haut",
                    subtitle: "Stop galets/électrolyseur + bâche ouverte (soleil/UV) + circulation.",
                    severity: .warning
                )
            )

            let litersTotal = poolVolumeM3 * 1000.0
            let litersToReplaceExact = litersToReplaceByDilution(currentMgPerL: avgChlorine, targetMgPerL: chlorineTarget, volumeM3: poolVolumeM3)
            let fractionExact = litersTotal > 0 ? (litersToReplaceExact / litersTotal) : 0

            // En pratique : commencer par 10–30% si l'excès est marqué
            if fractionExact >= 0.10 {
                let fractionSuggested = min(0.30, max(0.10, fractionExact))
                let litersSuggested = litersTotal * fractionSuggested
                appendUnique(
                    PoolAssistantAction(
                        systemImage: "drop.triangle.fill",
                        title: "Diluer",
                        subtitle: String(format: "Vidange + remplissage : ~%.0f L (≈ %.0f%%), puis re-mesurez.", roundToNearest10(litersSuggested), fractionSuggested * 100.0),
                        severity: .warning
                    )
                )
            }

            needsWait = true
            waitHours = max(waitHours, 24)
        }

        // 3) Filtration / filtre (quand dérive)
        if !hasHighChlorine {
            if avgChlorine < thresholds.chlorineMin || avgOrp < thresholds.orpMin || avgPh < thresholds.phMin || avgPh > thresholds.phMax || avgTemp >= 29 {
                appendUnique(
                    PoolAssistantAction(
                        systemImage: "line.3.horizontal.decrease.circle.fill",
                        title: "Filtration / filtre",
                        subtitle: String(format: "Vise ~%.0f h/j (≈ temp/2). Nettoie/contre-lave le filtre aujourd'hui.", recommendedFiltrationHours),
                        severity: .warning
                    )
                )
            }
        }

        // 4) Attendre + 5) Re-mesurer
        if needsWait {
            let waitSubtitle: String
            if waitHours >= 24 {
                waitSubtitle = "Attendez 24–48h, laissez circuler l'eau, et évitez la baignade pendant l'ajustement."
            } else {
                waitSubtitle = String(format: "Laissez filtrer %.0f h et évitez la baignade pendant l'ajustement.", waitHours)
            }

            appendUnique(
                PoolAssistantAction(
                    systemImage: "clock.fill",
                    title: "Attendre",
                    subtitle: waitSubtitle,
                    severity: .warning
                )
            )

            appendUnique(
                PoolAssistantAction(
                    systemImage: "scope",
                    title: "Re-tester",
                    subtitle: "Recontrôlez pH + chlore + ORP et ajustez si nécessaire.",
                    severity: .warning
                )
            )
        }

        let summary: String
        if actions.isEmpty {
            summary = "RAS : eau globalement stable"
        } else {
            summary = "Plan d'action recommandé"
        }

        // Limiter le nombre de cartes (UX) : on garde l'ordre du plan
        let limitedActions = Array(actions.prefix(5))

        return PoolAssistantAdvice(
            title: "Assistant Piscine",
            summary: summary,
            insights: insights,
            poolStatus: poolStatus,
            actions: limitedActions
        )
    }

    private static func makePoolStatus(
        avgTemp: Double,
        tempTrend: String,
        avgPh: Double,
        phTrend: String,
        avgChlorine: Double,
        chlorineTrend: String,
        avgOrp: Double,
        orpTrend: String,
        thresholds: NotificationThresholds
    ) -> PoolAssistantPoolStatus {
        // Définition simple de 3 états (vert/orange/rouge)
        let phCritical = avgPh < (thresholds.phMin - 0.3) || avgPh > (thresholds.phMax + 0.3)
        let chlorineCritical = avgChlorine < (thresholds.chlorineMin * 0.5) || avgChlorine > (thresholds.chlorineMax * 2.0)
        let orpCritical = avgOrp < (thresholds.orpMin - 100) || avgOrp > (thresholds.orpMax + 100)
        let tempCritical = avgTemp < (thresholds.temperatureMin - 3) || avgTemp > (thresholds.temperatureMax + 3)

        let phWarning = avgPh < thresholds.phMin || avgPh > thresholds.phMax
        let chlorineWarning = avgChlorine < thresholds.chlorineMin || avgChlorine > thresholds.chlorineMax
        let orpWarning = avgOrp < thresholds.orpMin || avgOrp > thresholds.orpMax
        let tempWarning = avgTemp < thresholds.temperatureMin || avgTemp > thresholds.temperatureMax

        let severity: PoolAssistantAction.Severity
        if phCritical || chlorineCritical || orpCritical || tempCritical {
            severity = .critical
        } else if phWarning || chlorineWarning || orpWarning || tempWarning {
            severity = .warning
        } else {
            severity = .info
        }

        let systemImage = "water.waves"

        let title: String
        switch severity {
        case .info:
            title = "Piscine OK"
        case .warning:
            title = "À surveiller"
        case .critical:
            title = "Action urgente"
        }

        // Message court orienté action (priorités)
        let subtitle: String
        if avgChlorine > thresholds.chlorineMax {
            subtitle = "Chlore trop haut \(chlorineTrend) : stop chlore + attendez 24–48h."
        } else if avgChlorine < thresholds.chlorineMin {
            subtitle = "Chlore trop bas \(chlorineTrend) : ajoutez du chlore en petites doses."
        } else if avgPh > thresholds.phMax {
            subtitle = "pH trop haut \(phTrend) : baissez le pH (le chlore agit moins)."
        } else if avgPh < thresholds.phMin {
            subtitle = "pH trop bas \(phTrend) : remontez le pH progressivement."
        } else if avgOrp < thresholds.orpMin {
            subtitle = "ORP bas \(orpTrend) : augmentez la désinfection + filtration."
        } else if avgTemp >= 29 {
            subtitle = "Eau chaude \(tempTrend) : surveillez et filtrez davantage."
        } else {
            subtitle = "Rien à signaler : gardez la filtration et testez régulièrement."
        }

        return PoolAssistantPoolStatus(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            severity: severity
        )
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func trend(from values: [Double]) -> String {
        guard let first = values.first, let last = values.last else { return "→" }
        let delta = last - first
        if abs(delta) < 0.001 { return "→" }
        return delta > 0 ? "↑" : "↓"
    }

    /// Règle pratique : durée de filtration (h/j) ≈ température/2
    private static func filtrationHoursFor(tempC: Double) -> Double {
        guard tempC > 0 else { return 8 }
        let hours = (tempC / 2.0).rounded()
        return max(8, min(24, hours))
    }

    /// delta mg/L à ajouter -> grammes de produit
    /// mg/L * L = mg ; 1000 mg = 1 g
    private static func gramsOfChlorineProductToIncrease(deltaMgPerL: Double, volumeM3: Double, availableChlorinePercent: Double) -> Double {
        let liters = volumeM3 * 1000.0
        let mgNeeded = deltaMgPerL * liters
        let gramsPure = mgNeeded / 1000.0
        let fraction = max(0.01, availableChlorinePercent / 100.0)
        return gramsPure / fraction
    }

    /// Dilution (remplacement d'une fraction d'eau) :
    /// Cnew = Cold * (1 - x)  => x = 1 - Cnew/Cold
    private static func litersToReplaceByDilution(currentMgPerL: Double, targetMgPerL: Double, volumeM3: Double) -> Double {
        guard currentMgPerL > 0, targetMgPerL > 0, currentMgPerL > targetMgPerL else { return 0 }
        let x = 1.0 - (targetMgPerL / currentMgPerL)
        let liters = volumeM3 * 1000.0
        return liters * max(0, min(1, x))
    }

    /// Dosage pH basé sur une règle simple configurable : g / 10m3 / 0.1 pH
    private static func gramsForPhAdjustment(deltaPh: Double, volumeM3: Double, doseGPer10m3Per0_1: Double) -> Double {
        guard deltaPh > 0 else { return 0 }
        let steps = deltaPh / 0.1
        let volumeFactor = volumeM3 / 10.0
        return doseGPer10m3Per0_1 * steps * volumeFactor
    }

    private static func defaultIfZero(_ value: Double, defaultValue: Double) -> Double {
        value > 0 ? value : defaultValue
    }

    private static func roundToNearest5(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    private static func roundToNearest10(_ value: Double) -> Double {
        (value / 10.0).rounded() * 10.0
    }
}
