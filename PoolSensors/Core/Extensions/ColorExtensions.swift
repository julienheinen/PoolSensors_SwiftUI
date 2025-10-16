//
//  ColorExtensions.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI
import UIKit

extension Color {
    /// Couleur de fond pour les cartes qui s'adapte automatiquement au mode clair/sombre
    /// Mode clair: Gris clair (systemGray6)
    /// Mode sombre: Gris foncé (RGB 38, 38, 38)
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.15, alpha: 1.0)  // Gris foncé pour mode sombre
                : UIColor.systemGray6                // Gris clair pour mode clair
        })
    }
    
    /// Couleur de fond secondaire pour les éléments moins importants
    static var secondaryCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.12, alpha: 1.0)  // Plus foncé en mode sombre
                : UIColor.systemGray5                // Légèrement plus foncé en mode clair
        })
    }
    
    /// Couleur pour le fond principal de l'app
    static var appBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    /// Couleur pour les bordures subtiles
    static var subtleBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.25, alpha: 1.0)
                : UIColor(white: 0.85, alpha: 1.0)
        })
    }
}
