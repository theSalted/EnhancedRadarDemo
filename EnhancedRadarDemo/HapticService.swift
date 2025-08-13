//
//  HapticService.swift
//  EnhancedRadarDemo
//
//  Created by Assistant on 8/12/25.
//

import SwiftUI
import UIKit

/// Simple haptic feedback service for easy use throughout the app
class HapticService {
    static let shared = HapticService()
    
    private init() {}
    
    /// Light haptic feedback - for subtle interactions like button highlights
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium haptic feedback - for standard button taps and selections
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy haptic feedback - for important actions and confirmations
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Success haptic - for successful operations
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic - for warnings and cautions
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic - for errors and failures
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Selection haptic - for picker wheels and selections
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Custom intensity haptic (iOS 13+)
    @available(iOS 13.0, *)
    func custom(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: intensity)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Add haptic feedback to any view interaction
    func haptic(_ type: HapticType, on trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            HapticService.shared.perform(type)
        }
    }
    
    /// Add haptic feedback on tap gesture
    func hapticTap(_ type: HapticType = .medium) -> some View {
        self.onTapGesture {
            HapticService.shared.perform(type)
        }
    }
}

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    case custom(CGFloat)
}

extension HapticService {
    func perform(_ type: HapticType) {
        switch type {
        case .light: light()
        case .medium: medium()
        case .heavy: heavy()
        case .success: success()
        case .warning: warning()
        case .error: error()
        case .selection: selection()
        case .custom(let intensity):
            if #available(iOS 13.0, *) {
                custom(intensity: intensity)
            } else {
                heavy()
            }
        }
    }
}

// MARK: - Global Convenience Functions

/// Quick haptic functions for even easier use
func haptic(_ type: HapticType) {
    HapticService.shared.perform(type)
}

func lightHaptic() { HapticService.shared.light() }
func mediumHaptic() { HapticService.shared.medium() }
func heavyHaptic() { HapticService.shared.heavy() }
func successHaptic() { HapticService.shared.success() }
func warningHaptic() { HapticService.shared.warning() }
func errorHaptic() { HapticService.shared.error() }
func selectionHaptic() { HapticService.shared.selection() }