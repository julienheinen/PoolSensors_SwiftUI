//
//  CalibrationView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSensor: SensorType = .temperature
    @State private var calibrationMode: CalibrationMode = .twoPoint
    
    // Valeurs de référence pour la calibration
    @State private var referenceValue1: String = ""
    @State private var referenceValue2: String = ""
    @State private var measuredValue1: String = ""
    @State private var measuredValue2: String = ""
    
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            sensorSelectionSection
            calibrationModeSection
            referencePoint1Section
            
            if calibrationMode == .twoPoint {
                referencePoint2Section
            }
            
            currentValuesSection
            actionSection
        }
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Calibration réussie", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Le capteur \(selectedSensor.name) a été calibré avec succès.")
        }
        .alert("Erreur de calibration", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var sensorSelectionSection: some View {
        Section {
            Picker("Type de capteur", selection: $selectedSensor) {
                ForEach(SensorType.allCases, id: \.self) { sensor in
                    HStack {
                        Image(systemName: sensor.icon)
                        Text(sensor.name)
                    }
                    .tag(sensor)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Text("Unité")
                Spacer()
                Text(selectedSensor.unit)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Capteur à calibrer")
        }
    }
    
    private var calibrationModeSection: some View {
        Section {
            Picker("Mode", selection: $calibrationMode) {
                Text("Point zéro").tag(CalibrationMode.zeroPoint)
                Text("Deux points").tag(CalibrationMode.twoPoint)
            }
            .pickerStyle(.segmented)
            
            Text(calibrationMode == .zeroPoint ?
                "Calibration à un seul point de référence (réinitialisation)." :
                "Calibration à deux points pour une meilleure précision.")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Mode de calibration")
        }
    }
    
    private var referencePoint1Section: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Valeur de référence")
                    Spacer()
                    TextField("Ex: 7.0", text: $referenceValue1)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(selectedSensor.unit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Valeur mesurée")
                    Spacer()
                    TextField("Ex: 6.8", text: $measuredValue1)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(selectedSensor.unit)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(calibrationMode == .zeroPoint ? "Point de référence" : "Point de référence 1")
        } footer: {
            Text(getInstructionText1())
                .font(.caption)
        }
    }
    
    private var referencePoint2Section: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Valeur de référence")
                    Spacer()
                    TextField("Ex: 10.0", text: $referenceValue2)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(selectedSensor.unit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Valeur mesurée")
                    Spacer()
                    TextField("Ex: 10.2", text: $measuredValue2)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(selectedSensor.unit)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Point de référence 2")
        } footer: {
            Text(getInstructionText2())
                .font(.caption)
        }
    }
    
    private var currentValuesSection: some View {
        Section {
                if let currentValue = getCurrentSensorValue() {
                    HStack {
                        Text(selectedSensor.name)
                        Spacer()
                        Text(currentValue)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                } else {
                Text("Aucune donnée disponible")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Valeurs actuelles du capteur")
        }
    }
    
    private var actionSection: some View {
        Section {
                Button(action: performCalibration) {
                    HStack {
                        Spacer()
                        Label("Appliquer la calibration", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
            }
            .disabled(!isCalibrationValid())
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentSensorValue() -> String? {
        guard let latestData = viewModel.sensorData.last else {
            return nil
        }
        
        switch selectedSensor {
        case .temperature:
            return "\(String(format: "%.1f", latestData.temperature)) \(selectedSensor.unit)"
        case .ph:
            return "\(String(format: "%.1f", latestData.ph)) \(selectedSensor.unit)"
        case .chlorine:
            return "\(String(format: "%.1f", latestData.chlorine)) \(selectedSensor.unit)"
        case .orp:
            return "\(String(format: "%.0f", latestData.orp)) \(selectedSensor.unit)"
        }
    }
    
    private func getInstructionText1() -> String {
        switch selectedSensor {
        case .temperature:
            return "Plongez le capteur dans un bain à température connue (ex: glace à 0°C)."
        case .ph:
            return "Plongez la sonde dans une solution tampon pH 7.0."
        case .chlorine:
            return "Utilisez une solution de référence à 1.0 mg/L de chlore."
        case .orp:
            return "Utilisez une solution de référence à 650 mV."
        }
    }
    
    private func getInstructionText2() -> String {
        switch selectedSensor {
        case .temperature:
            return "Plongez le capteur dans un bain à température élevée connue (ex: 25°C)."
        case .ph:
            return "Plongez la sonde dans une solution tampon pH 10.0."
        case .chlorine:
            return "Utilisez une solution de référence à 3.0 mg/L de chlore."
        case .orp:
            return "Utilisez une solution de référence à 750 mV."
        }
    }
    
    private func isCalibrationValid() -> Bool {
        // Vérifier que les champs sont remplis
        guard !referenceValue1.isEmpty && !measuredValue1.isEmpty else {
            return false
        }
        
        if calibrationMode == .twoPoint {
            guard !referenceValue2.isEmpty && !measuredValue2.isEmpty else {
                return false
            }
        }
        
        // Vérifier que les valeurs sont des nombres valides
        guard Double(referenceValue1) != nil && Double(measuredValue1) != nil else {
            return false
        }
        
        if calibrationMode == .twoPoint {
            guard Double(referenceValue2) != nil && Double(measuredValue2) != nil else {
                return false
            }
        }
        
        return true
    }
    
    private func performCalibration() {
        guard let ref1 = Double(referenceValue1),
              let meas1 = Double(measuredValue1) else {
            errorMessage = "Valeurs invalides pour le point 1."
            showErrorAlert = true
            return
        }
        
        if calibrationMode == .zeroPoint {
            // Calibration simple: calculer l'offset
            let offset = ref1 - meas1
            
            print("🔧 Calibration point zéro:")
            print("   Capteur: \(selectedSensor.name)")
            print("   Référence: \(ref1) \(selectedSensor.unit)")
            print("   Mesuré: \(meas1) \(selectedSensor.unit)")
            print("   Offset: \(offset) \(selectedSensor.unit)")
            
            // Sauvegarder l'offset (à implémenter dans AppViewModel)
            saveCalibration(offset: offset, slope: 1.0)
            
        } else {
            // Calibration deux points
            guard let ref2 = Double(referenceValue2),
                  let meas2 = Double(measuredValue2) else {
                errorMessage = "Valeurs invalides pour le point 2."
                showErrorAlert = true
                return
            }
            
            // Calculer la pente et l'offset
            let slope = (ref2 - ref1) / (meas2 - meas1)
            let offset = ref1 - (slope * meas1)
            
            print("🔧 Calibration deux points:")
            print("   Capteur: \(selectedSensor.name)")
            print("   Point 1 - Référence: \(ref1), Mesuré: \(meas1)")
            print("   Point 2 - Référence: \(ref2), Mesuré: \(meas2)")
            print("   Pente: \(slope)")
            print("   Offset: \(offset)")
            
            // Sauvegarder la calibration
            saveCalibration(offset: offset, slope: slope)
        }
        
        showSuccessAlert = true
    }
    
    private func saveCalibration(offset: Double, slope: Double) {
        // Sauvegarder dans UserDefaults
        let key = "calibration_\(selectedSensor.rawValue)"
        let calibrationData: [String: Double] = [
            "offset": offset,
            "slope": slope,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONEncoder().encode(calibrationData) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("💾 Calibration sauvegardée: \(key)")
        }
    }
}

// MARK: - Supporting Types

enum SensorType: String, CaseIterable {
    case temperature = "temperature"
    case ph = "ph"
    case chlorine = "chlorine"
    case orp = "orp"
    
    var name: String {
        switch self {
        case .temperature: return "Température"
        case .ph: return "pH"
        case .chlorine: return "Chlore"
        case .orp: return "ORP"
        }
    }
    
    var icon: String {
        switch self {
        case .temperature: return "thermometer"
        case .ph: return "drop.fill"
        case .chlorine: return "circle.hexagongrid.fill"
        case .orp: return "waveform.path.ecg"
        }
    }
    
    var unit: String {
        switch self {
        case .temperature: return "°C"
        case .ph: return ""
        case .chlorine: return "mg/L"
        case .orp: return "mV"
        }
    }
}

enum CalibrationMode {
    case zeroPoint
    case twoPoint
}

#Preview {
    NavigationView {
        CalibrationView()
            .environmentObject(AppViewModel())
    }
}
