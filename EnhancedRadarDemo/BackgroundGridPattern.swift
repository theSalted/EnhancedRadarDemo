//
//  BackgroundGridPattern.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/12/25.
//


import SwiftUI
import OSLog

struct BackgroundGridPattern: View {
    // Grid look
    var spacing: CGFloat = 16
    var majorEvery: Int = 4
    var color: Color = .secondary.opacity(0.25)
    var majorColor: Color = .secondary.opacity(0.25)
    var lineWidth: CGFloat = 0.5
    var majorLineWidth: CGFloat = 1

    // Animation controls
    /// External offset you can drive (e.g. with scroll/camera)
    var phase: CGSize = .zero
    /// If non-zero, the grid will auto-scroll at this velocity (pts/sec)
    var velocity: CGSize = .zero
    /// Use pixel-snapping if your lines look fuzzy
    var snapToPixel: Bool = true
    
    // 3D Effect controls
    /// Enable 3D perspective effect
    var enable3D: Bool = false
    /// Use gyroscope for dynamic 3D effect
    var useGyro: Bool = false
    /// Sensitivity of gyro effect (0.1 to 2.0)
    var gyroSensitivity: Double = 1.0
    /// Manual 3D rotation (used when gyro is disabled)
    var manual3DRotation: CGSize = .zero
    /// Perspective depth (smaller = more dramatic)
    var perspectiveDepth: CGFloat = 500
    /// Disable pan for grids with velocity
    var disablePan: Bool = false
    
    @ObservedObject private var gyro = GyroService.shared

    var body: some View {
        Group {
            if velocity == .zero {
                gridCanvas(phase: phase)
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let auto = CGSize(width: CGFloat(t) * velocity.width,
                                      height: CGFloat(t) * velocity.height)
                    gridCanvas(phase: CGSize(width: phase.width + auto.width,
                                             height: phase.height + auto.height))
                }
            }
        }
        .ignoresSafeArea()
        .drawingGroup(opaque: false, colorMode: .linear)
        .if(enable3D) { view in
            view.apply3DEffect(
                useGyro: useGyro,
                gyro: gyro,
                gyroSensitivity: gyroSensitivity,
                manual3DRotation: manual3DRotation,
                perspectiveDepth: perspectiveDepth,
                disablePan: disablePan
            )
        }
        .onAppear {
            if useGyro && enable3D {
                gyro.requestStart()
            }
        }
        .onDisappear {
            if useGyro && enable3D {
                gyro.requestStop()
            }
        }
    }

    @ViewBuilder
    private func gridCanvas(phase: CGSize) -> some View {
        Canvas { context, size in
            // Add padding to extend grid beyond visible area when rotated
            let padding: CGFloat = enable3D ? 600 : 0
            let w = size.width + padding * 2
            let h = size.height + padding * 2

            // Wrap phase into a single spacing to avoid huge values
            @inline(__always)
            func wrapped(_ value: CGFloat, by step: CGFloat) -> CGFloat {
                guard step > 0 else { return 0 }
                let r = value.remainder(dividingBy: step)
                return r >= 0 ? r : (r + step)
            }

            let ox = wrapped(phase.width, by: spacing)
            let oy = wrapped(phase.height, by: spacing)

            var minor = Path()
            var major = Path()

            // Pixel snap: align to half-pixel for hairlines on 1x scale
            let half: CGFloat = snapToPixel ? 0.5 : 0

            // Vertical lines (extended with padding)
            var col = 0
            for x in stride(from: -ox - padding, through: w, by: spacing) {
                let px = x.rounded() + half
                var p = Path()
                p.move(to: CGPoint(x: px, y: -padding))
                p.addLine(to: CGPoint(x: px, y: h))
                if (col % max(majorEvery, 1) == 0) { major.addPath(p) } else { minor.addPath(p) }
                col += 1
            }

            // Horizontal lines (extended with padding)
            var row = 0
            for y in stride(from: -oy - padding, through: h, by: spacing) {
                let py = y.rounded() + half
                var p = Path()
                p.move(to: CGPoint(x: -padding, y: py))
                p.addLine(to: CGPoint(x: w, y: py))
                if (row % max(majorEvery, 1) == 0) { major.addPath(p) } else { minor.addPath(p) }
                row += 1
            }

            context.stroke(minor, with: .color(color), lineWidth: lineWidth)
            context.stroke(major, with: .color(majorColor), lineWidth: majorLineWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .if(enable3D) { view in
            // Scale up significantly to ensure coverage during rotation
            view.scaleEffect(1.8)
        }
    }
}
