//
//  ContentView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "airplane")
            Text("Enhanced Radar")
        }
        .sheet(isPresented: .constant(true)) {
            EventDetailSheetView()
        }
    }
}

struct EventDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                #if DEBUG && targetEnvironment(simulator) && canImport(SwiftUI)
                simulatorStyleFix
                #endif
                
                BackgroundGridPattern(
                    spacing: 80,
                    majorEvery: 1,
                    velocity: CGSize(width: -100, height: -50)
                )
                .ignoresSafeArea()
                
                
                VStack {
                    Spacer()
                    Image("DeltaPlane")
                        .resizable()
                        .rotationEffect(.degrees(13))
                        .scaledToFit()
                        .padding()
                    Spacer()
                    VStack(alignment: .leading) {
                        
                        // MARK: Transcription
                        Text("Delta 1008, La Guardia tower, contact New York Departure")
                            .font(.system(size: 32, weight: .semibold))
                            .padding()
                        
                        // MARK: Banner
                        Rectangle()
                            .frame(height: 47)
                            .foregroundStyle(.incidentForeground)
                        
                        
                        
                        // MARK: Radio
                        ZStack(alignment: .top) {
                            Rectangle()
                                .foregroundStyle(.eventAccent)
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(.black.opacity(0.13))
                                    Image(systemName: "airplane")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.eventForeground)
                                        .padding(10)
                                        .offset(x: 2) // TODO: A more permanent solution
                                        .rotationEffect(.degrees(225))
                                    
                                }
                                .frame(width: 45, height: 45)
                                HStack(alignment: .top) {
                                    Text("SFO")
                                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.eventForeground)
                                    
                                    Text("San Francisco International Tower")
                                        .bold()
                                        .foregroundStyle(.eventForeground)
                                        .offset(y: 10)
                                    
                                }
                                Spacer()
                            }
                            .frame(height: 45)
                            .padding()
                        }
                        .frame(height: 141)
                    }
                    
                }
                .ignoresSafeArea()
                .frame(maxHeight: .infinity)
//                .background {
//                    Rectangle().foregroundStyle(.blue).opacity(0.5)
//                }
                
                mask
                
            }
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("LIVE")
                    
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundStyle(.red)
                        }
                }
            }
        }
    }
    
    var mask: some View {
        Rectangle()
            .foregroundStyle(
                Gradient(stops: [
                    .init(color: Color(uiColor: .systemBackground).opacity(0.9), location: 0.1),
                    .init(color: .clear, location: 0.3)
                ])
            )
            .ignoresSafeArea()
    }
    
    var simulatorStyleFix: some View {
        // A quick hack for a SwiftUI bug that make sheet stuck in light mode
        Rectangle().foregroundStyle(.background)
            .ignoresSafeArea()
    }
}

//struct PlanePreview: View {
//    var name: String
//    var degrees: Double
//
//    
//    init (_ name: String, degrees: Double = 13) {
//        self.name = name
//        self.degrees = degrees
//    }
//    
//    var body: some View {
//        ZStack {
//            // Background
//            BackgroundGridPattern(
//                spacing: 80,
//                majorEvery: 1,
//                velocity: CGSize(width: -100, height: -50)
//            )
//            .ignoresSafeArea()
//            
//            Image(name)
//                .resizable()
//                .rotationEffect(.degrees(self.degrees))
//                .scaledToFit()
//                .padding()
//        }
//    }
//}



struct BackgroundGridPattern: View {
    // Grid look
    var spacing: CGFloat = 16
    var majorEvery: Int = 4
    var color: Color = .secondary.opacity(0.25)
    var majorColor: Color = .secondary.opacity(0.45)
    var lineWidth: CGFloat = 0.5
    var majorLineWidth: CGFloat = 1

    // Animation controls
    /// External offset you can drive (e.g. with scroll/camera)
    var phase: CGSize = .zero
    /// If non-zero, the grid will auto-scroll at this velocity (pts/sec)
    var velocity: CGSize = .zero
    /// Use pixel-snapping if your lines look fuzzy
    var snapToPixel: Bool = true

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
    }

    @ViewBuilder
    private func gridCanvas(phase: CGSize) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

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

            // Vertical lines
            var col = 0
            for x in stride(from: -ox, through: w, by: spacing) {
                let px = x.rounded() + half
                var p = Path()
                p.move(to: CGPoint(x: px, y: 0))
                p.addLine(to: CGPoint(x: px, y: h))
                if (col % max(majorEvery, 1) == 0) { major.addPath(p) } else { minor.addPath(p) }
                col += 1
            }

            // Horizontal lines
            var row = 0
            for y in stride(from: -oy, through: h, by: spacing) {
                let py = y.rounded() + half
                var p = Path()
                p.move(to: CGPoint(x: 0, y: py))
                p.addLine(to: CGPoint(x: w, y: py))
                if (row % max(majorEvery, 1) == 0) { major.addPath(p) } else { minor.addPath(p) }
                row += 1
            }

            context.stroke(minor, with: .color(color), lineWidth: lineWidth)
            context.stroke(major, with: .color(majorColor), lineWidth: majorLineWidth)
        }
    }
}

#Preview {
    ContentView()
}
