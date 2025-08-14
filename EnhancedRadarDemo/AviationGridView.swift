//
//  AviationGridView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/14/25.
//

import SwiftUI

/// Aviation-specific grid view that represents aircraft perspective
/// - Taxi state: 90° pitch (looking down the runway)
/// - Flight state: 0° pitch (level flight perspective)
struct AviationGridView: View {
    // Grid properties (passed through to InfiniteGridView)
    var spacing: CGFloat = 16
    var majorEvery: Int = 4
    var color: Color = .secondary.opacity(1)
    var majorColor: Color = .secondary.opacity(1)
    var lineWidth: CGFloat = 0.5
    var majorLineWidth: CGFloat = 1
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var allowsCameraControl: Bool = false
    var gyroSensitivityX: CGFloat? = nil
    var gyroSensitivityY: CGFloat? = nil
    
    // Aviation-specific properties
    @Binding var flightState: FlightState
    var animationDuration: Double = 2.0
    
    // Internal state for smooth animation
    @State private var currentPitch: CGFloat = 0
    
    // Computed spacing that adjusts smoothly based on animated pitch
    private var adjustedSpacing: CGFloat {
        let tiltFactor = abs(currentPitch) / 90.0  // 0.0 to 1.0
        return spacing * (1.0 + tiltFactor * 1.0)  // 1.0 to 2.0x spacing
    }
    
    enum FlightState {
        case taxing       // 90° pitch - looking down runway
        case flight     // 0° pitch - level flight perspective
        
        var targetPitch: CGFloat {
            switch self {
            case .taxing:
                return 100.0     // Looking down
            case .flight:
                return 0.0      // Level
            }
        }
        
        var description: String {
            switch self {
            case .taxing:
                return "Taxi"
            case .flight:
                return "Flight"
            }
        }
    }
    
    var body: some View {
        InfiniteGridView(
            spacing: adjustedSpacing,
            majorEvery: majorEvery,
            color: color,
            majorColor: majorColor,
            lineWidth: lineWidth,
            majorLineWidth: majorLineWidth,
            velocityX: velocityX,
            velocityY: velocityY,
            allowsCameraControl: allowsCameraControl,
            gyroSensitivityX: gyroSensitivityX,
            gyroSensitivityY: gyroSensitivityY,
            cameraRotationX: currentPitch,  // This creates the taxi/flight perspective
            cameraRotationY: nil,
            cameraRotationZ: nil,
            manualRotationAnimationDuration: animationDuration,
            animateSpacingChanges: true
        )
        .onAppear {
            // Initialize with current flight state
            currentPitch = flightState.targetPitch
        }
        .onChange(of: flightState) { oldState, newState in
            // Smooth animation between flight states
            withAnimation(.easeInOut(duration: animationDuration)) {
                currentPitch = newState.targetPitch
            }
        }
    }
}

#Preview {
    struct AviationGridPreview: View {
        @State private var flightState: AviationGridView.FlightState = .flight
        
        var body: some View {
            ZStack {
                AviationGridView(
                    spacing: 10,
                    majorEvery: 1,
                    color: .white.opacity(0.5),
                    majorColor: .white.opacity(1),
                    lineWidth: 0.1,
                    majorLineWidth: 0.1,
                    velocityX: 20,
                    velocityY: -10,
                    flightState: $flightState,
                    animationDuration: 0.6
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button("Taxi Mode") {
                            flightState = .taxing
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(flightState == .taxing)
                        
                        Button("Flight Mode") {
                            flightState = .flight
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(flightState == .flight)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                    
                    Text("Current State: \(flightState.description)")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom)
                }
            }
        }
    }
    
    return AviationGridPreview()
}
