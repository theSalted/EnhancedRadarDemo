//
//  GyroService.swift
//  EnhancedRadarDemo
//
//  Created by Assistant on 8/12/25.
//

import SwiftUI
import CoreMotion
import Combine
import OSLog

/// A service that provides easy access to device gyroscope and motion data
class GyroService: ObservableObject {
    static let shared = GyroService()
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let logger = Logger(subsystem: "EnhancedRadarDemo", category: "GyroService")
    
    /// Current device attitude (pitch, roll, yaw) in radians
    @Published var attitude: CMAttitude?
    
    /// Normalized rotation values (-1 to 1) for easy UI usage
    @Published var normalizedRotation = NormalizedRotation()
    
    /// Whether gyro is available on this device
    @Published var isAvailable: Bool = false
    
    /// Whether the service is currently active
    @Published var isActive: Bool = false
    
    /// Reference count for multiple views using the service
    private var referenceCount = 0
    
    /// Update frequency in Hz (default: 60)
    var updateFrequency: Double = 60 {
        didSet {
            if isActive {
                stop()
                start()
            }
        }
    }
    
    struct NormalizedRotation {
        var pitch: Double = 0  // Device tilt forward/backward (-1 to 1)
        var roll: Double = 0   // Device tilt left/right (-1 to 1)
        var yaw: Double = 0    // Device rotation around vertical axis (-1 to 1)
        
        /// Combined 2D offset for UI effects
        var offset: CGSize {
            CGSize(width: roll, height: pitch)
        }
        
        /// 3D transform for perspective effects
        var transform3D: CATransform3D {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500.0 // Perspective
            
            // Apply rotations
            transform = CATransform3DRotate(transform, CGFloat(pitch * .pi / 6), 1, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(roll * .pi / 6), 0, 1, 0)
            
            return transform
        }
    }
    
    private init() {
        isAvailable = motionManager.isDeviceMotionAvailable
        queue.maxConcurrentOperationCount = 1
    }
    
    /// Request to start receiving gyro updates (reference counted)
    func requestStart() {
        referenceCount += 1
        logger.debug("requestStart - refCount: \(self.referenceCount)")
        if referenceCount == 1 {
            start()
        }
    }
    
    /// Request to stop receiving gyro updates (reference counted)
    func requestStop() {
        referenceCount = max(0, referenceCount - 1)
        logger.debug("requestStop - refCount: \(self.referenceCount)")
        if referenceCount == 0 {
            stop()
        }
    }
    
    /// Start receiving gyro updates (internal)
    private func start() {
        logger.debug("start - available: \(self.isAvailable), active: \(self.isActive)")
        guard isAvailable, !isActive else { 
            logger.debug("start skipped")
            return 
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / updateFrequency
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            if let error = error {
                self?.logger.error("Motion update error: \(error.localizedDescription)")
            }
            guard let motion = motion, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.attitude = motion.attitude
                self?.updateNormalizedValues(motion.attitude)
            }
        }
        
        isActive = true
        logger.info("Gyro started successfully")
    }
    
    /// Stop receiving gyro updates (internal)
    private func stop() {
        guard isActive else { return }
        
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        
        // Reset to neutral position
        withAnimation(.easeOut(duration: 0.3)) {
            normalizedRotation = NormalizedRotation()
            attitude = nil
        }
    }
    
    private var updateCount = 0
    private func updateNormalizedValues(_ attitude: CMAttitude) {
        // Normalize to -1 to 1 range with reasonable limits
        // Pitch: ±45 degrees for more symmetric range
        // Roll: ±60 degrees for horizontal (less restrictive)
        // Yaw: ±180 degrees = ±π radians
        
        let maxPitch = Double.pi / 4  // 45 degrees for better symmetry
        let maxRoll = Double.pi / 3   // 60 degrees
        let maxYaw = Double.pi
        
        // Don't invert pitch - keep it natural
        // Inverted roll for parallax effect
        normalizedRotation.pitch = max(-1, min(1, attitude.pitch / maxPitch))
        normalizedRotation.roll = max(-1, min(1, -attitude.roll / maxRoll))
        normalizedRotation.yaw = max(-1, min(1, attitude.yaw / maxYaw))
        
        // Log first few updates to verify values
        // updateCount += 1
        // if updateCount < 10 || updateCount % 100 == 0 {
        //     logger.debug("Gyro values - pitch: \(self.normalizedRotation.pitch), roll: \(self.normalizedRotation.roll)")
        // }
    }
}

/// View modifier for easy gyro-based effects
struct GyroEffect: ViewModifier {
    @StateObject private var gyro = GyroService.shared
    
    var sensitivity: Double = 1.0
    var maxOffset: CGFloat = 20
    var enable3D: Bool = false
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: gyro.normalizedRotation.roll * maxOffset * sensitivity,
                y: -gyro.normalizedRotation.pitch * maxOffset * sensitivity
            )
            .rotation3DEffect(
                enable3D ? .degrees(gyro.normalizedRotation.pitch * 10 * sensitivity) : .zero,
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                enable3D ? .degrees(gyro.normalizedRotation.roll * 10 * sensitivity) : .zero,
                axis: (x: 0, y: 1, z: 0)
            )
            .onAppear {
                gyro.requestStart()
            }
            .onDisappear {
                gyro.requestStop()
            }
    }
}

extension View {
    /// Apply gyro-based motion effects to any view
    func gyroEffect(
        sensitivity: Double = 1.0,
        maxOffset: CGFloat = 20,
        enable3D: Bool = false
    ) -> some View {
        modifier(GyroEffect(
            sensitivity: sensitivity,
            maxOffset: maxOffset,
            enable3D: enable3D
        ))
    }
}
