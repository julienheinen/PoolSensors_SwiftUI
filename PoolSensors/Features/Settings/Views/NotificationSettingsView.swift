//
//  NotificationSettingsView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var notificationService = NotificationService.shared
    @State private var thresholds: NotificationThresholds
    @State private var showingSaveAlert = false
    
    init() {
        _thresholds = State(initialValue: NotificationService.shared.thresholds)
    }
    
    var body: some View {
        Form {
            // Section autorisation
            Section {
                HStack {
                    Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundColor(notificationService.isAuthorized ? .green : .orange)
                    
                    Text(notificationService.isAuthorized ? "Notifications activées" : "Notifications désactivées")
                        .font(.body)
                    
                    Spacer()
                }
                
                if !notificationService.isAuthorized {
                    Button("Activer les notifications") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                }
            } header: {
                Text("Statut")
            } footer: {
                Text("Les notifications vous alertent en cas de valeurs anormales.")
            }
            
            // Section types d'alertes
            Section("Types d'alertes") {
                Toggle("Température", isOn: $thresholds.enableTemperatureAlerts)
                Toggle("pH", isOn: $thresholds.enablePhAlerts)
                Toggle("Chlore", isOn: $thresholds.enableChlorineAlerts)
                Toggle("ORP", isOn: $thresholds.enableOrpAlerts)
                Toggle("Connexion", isOn: $thresholds.enableConnectionAlerts)
            }
            
            // Section seuils de température
            if thresholds.enableTemperatureAlerts {
                Section("Seuils de Température") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $thresholds.temperatureMin, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("°C")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $thresholds.temperatureMax, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("°C")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section seuils de pH
            if thresholds.enablePhAlerts {
                Section("Seuils de pH") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $thresholds.phMin, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $thresholds.phMax, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
            }
            
            // Section seuils de chlore
            if thresholds.enableChlorineAlerts {
                Section("Seuils de Chlore") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $thresholds.chlorineMin, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("mg/L")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $thresholds.chlorineMax, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("mg/L")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section seuils d'ORP
            if thresholds.enableOrpAlerts {
                Section("Seuils d'ORP") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $thresholds.orpMin, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("mV")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $thresholds.orpMax, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("mV")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section cooldown
            Section {
                Stepper(value: $thresholds.alertCooldownDuration, in: 60...3600, step: 60) {
                    HStack {
                        Text("Délai entre alertes")
                        Spacer()
                        Text("\(Int(thresholds.alertCooldownDuration / 60)) min")
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Durée minimale entre deux notifications du même type pour éviter le spam.")
            }
            
            // Actions
            Section {
                Button("Tester une notification") {
                    NotificationService.shared.sendNotification(
                        title: "🧪 Test de notification",
                        body: "Les notifications fonctionnent correctement !",
                        category: "test"
                    )
                }
                
                Button("Effacer toutes les notifications", role: .destructive) {
                    NotificationService.shared.clearAllNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sauvegarder") {
                    saveSettings()
                }
                .fontWeight(.semibold)
            }
        }
        .alert("Paramètres sauvegardés", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Les seuils de notification ont été mis à jour.")
        }
    }
    
    private func saveSettings() {
        thresholds.save()
        notificationService.thresholds = thresholds
        showingSaveAlert = true
        print("💾 Paramètres de notification sauvegardés")
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
