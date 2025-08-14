//
//  RadioSheetView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//


import SwiftUI
import OSLog

struct RadioSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var liveTranscript: [TranscriptLine] = [
        TranscriptLine(speaker: "ATC", text: "Delta 1008, La Guardia Tower, contact New York Departure.")
    ]
    @State private var feedIndex: Int = 0
    @State private var feedTimer: Timer? = nil
    
    struct TranscriptLine: Identifiable {
        let id = UUID()
        let speaker: String
        let text: String
    }
    
    // Pseudo "live" sample lines to feed into the UI
    private let sampleTranscript: [TranscriptLine] = [
        TranscriptLine(speaker: "ATC", text: "Delta 1008, La Guardia Tower, contact New York Departure."),
        TranscriptLine(speaker: "DAL1008", text: "Over to Departure, Delta 1008. Good day."),
        TranscriptLine(speaker: "Departure", text: "Delta 1008, radar contact. Climb and maintain three thousand."),
        TranscriptLine(speaker: "DAL1008", text: "Climb and maintain three thousand, Delta 1008."),
        TranscriptLine(speaker: "Departure", text: "Turn right heading two one zero, vectors JFK."),
        TranscriptLine(speaker: "DAL1008", text: "Right two one zero, vectors JFK, Delta 1008."),
        TranscriptLine(speaker: "Departure", text: "Maintain two one zero knots."),
        TranscriptLine(speaker: "DAL1008", text: "Maintain two one zero knots, Delta 1008."),
        TranscriptLine(speaker: "Departure", text: "Delta 1008, say souls on board and fuel remaining."),
        TranscriptLine(speaker: "DAL1008", text: "One six three souls, fuel eight point five."),
        TranscriptLine(speaker: "Departure", text: "Roger. Expect ILS runway two two left.")
    ]

    // Schedule the next pseudo-live line at a random 3–5s delay and loop forever.
    private func scheduleNextFeed() {
        feedTimer?.invalidate()
        let delay = Double.random(in: 3.0...5.0)
        feedTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            DispatchQueue.main.async {
                // Append next line
                let line = sampleTranscript[feedIndex]
                liveTranscript.append(line)
                
                // Advance and wrap around to repeat forever
                feedIndex = (feedIndex + 1) % sampleTranscript.count
                
                // Optionally cap history to avoid unbounded growth (tweak as needed)
                if liveTranscript.count > 300 {
                    liveTranscript.removeFirst(liveTranscript.count - 300)
                }
                
                // Chain the next event
                scheduleNextFeed()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                InfiniteGridView(
                    spacing: 10,
                    majorEvery: 1,
                    color: .secondary.opacity(0.5),
                    majorColor: .secondary.opacity(0.25),
                    lineWidth: 0.1,
                    majorLineWidth: 0.1,
                    velocityX: 20,
                    velocityY: -10,
                    allowsCameraControl: false
                )
                .ignoresSafeArea()
                .mask {
                    GeometryReader { proxy in
                        Rectangle().fill(
                            .radialGradient(
                                stops: [
                                    .init(color: .white, location: 0.0),
                                    .init(color: .white, location: 0.45),
                                    .init(color: .clear, location: 0.9)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: min(proxy.size.width, proxy.size.height) * 0.65
                            )
                        )
                        .offset(y: -170)
                    }
                }
                
                Rectangle()
                    .foregroundStyle(
                        Gradient(stops: [
                            .init(color: .clear, location: 0.1),
                            .init(color: Color(uiColor: .systemBackground).opacity(0.9), location: 0.7),
                            
                        ])
                    )
                    .ignoresSafeArea()
                
                
                
                VStack {
                    Spacer()
                    Image("DeltaPlane")
                        .resizable()
                        .rotationEffect(.degrees(13))
                        .scaledToFit()
                        .padding()
//                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: Transcription
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    Spacer(minLength: 300)
                                    ForEach(liveTranscript) { line in
                                        Text(line.speaker)
                                            .font(.system(size: 24, weight: .semibold))
                                            .padding(.horizontal)
                                            .padding(.bottom, 5)
                                            .foregroundStyle(.primary.secondary)
                                        Text(line.text)
                                            .font(.system(size: 32, weight: .semibold))
                                            .padding([.horizontal, .bottom])
                                    }
                                    Color.clear
                                        .frame(height: 1)
                                        .id("BOTTOM")
                                }
                            }
                            .defaultScrollAnchor(.bottom)
                            .onChange(of: liveTranscript.count) { oldCount, newCount in
                                withAnimation(.easeOut(duration: 0.35)) {
                                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                                }
                                
                                // Light haptic for new transcript (skip initial load)
                                if oldCount > 0 && newCount > oldCount {
                                    HapticService.shared.light()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .white.opacity(0.3), location: 0.3),
                                    .init(color: .white, location: 0.92),
                                    .init(color: .white, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .onAppear {
                            // Show an initial line immediately so the UI never appears empty
                            // Begin the randomized 3–5s feed loop
                            scheduleNextFeed()
                        }
                        .onDisappear {
                            feedTimer?.invalidate()
                        }
                        
                        
                        
                        // MARK: Banner
                        ZStack {
                            Rectangle()
                                .frame(height: 47)
                                .foregroundStyle(.bannerIncidentBackground)
                            HStack {
                                Text("Delta Engine Failure")
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(.bannerForeground)
                                
                                Spacer()
                                
                                Text("1d ago")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.bannerIncidentBackground)
                                    .padding(5)
                                    .padding(.horizontal, 2)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6)
                                    }
                            }
                            .padding(.horizontal)
                        }
                        
                        
                        // MARK: Radio
                        ZStack(alignment: .top) {
                            Rectangle()
                                .foregroundStyle(.radioBackground)
                            
                            // MARK: Airport Info
                            VStack {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundStyle(.black.opacity(0.13))
                                        Image(systemName: "airplane")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.radioForeground)
                                            .padding(10)
                                            .offset(x: 2) // TODO: A more permanent solution
                                            .rotationEffect(.degrees(225))
                                        
                                    }
                                    .frame(width: 45, height: 45)
                                    VStack {
                                        HStack(alignment: .top, spacing: 15) {
                                            Text("SFO")
                                                .font(.system(size: 54, weight: .heavy, design: .rounded))
                                                .foregroundStyle(.radioForeground)
                                            
                                            Text("San Francisco International Tower")
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundStyle(.radioForeground)
                                                .offset(y: 10)
                                            
                                        }
                                        
                                        
                                    }
                                    
                                    Spacer()
                                }
                                .frame(height: 45)
                                .padding()
                                .padding(.top, 10)
                                
                                // MARK: Audio Visualizer
                                AudioVisualizerView(
                                    barCount: 56,
                                    height: 24,
                                    verticalScale: 1.2,
                                    spacing: 2
                                )
                                .foregroundStyle(.radioForeground)
                                .padding(.bottom, 10)
                            }
                            
                            
                        }
                        .frame(height: 150)
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
                        HapticService.shared.medium()
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
                    .init(color: .clear, location: 0.3),
                    
                ])
            )
            .ignoresSafeArea()
    }
}



// MARK: - Helper Extensions for 3D Effect

extension View {
    /// Conditional view modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply 3D perspective effect with optional gyro
    func apply3DEffect(
        useGyro: Bool,
        gyro: GyroService,
        gyroSensitivity: Double,
        manual3DRotation: CGSize,
        perspectiveDepth: CGFloat,
        disablePan: Bool = false
    ) -> some View {
        let rotation = useGyro
            ? CGSize(
                width: gyro.normalizedRotation.roll * 35 * gyroSensitivity,  // Roll sensitivity (left/right)
                height: 0  // Disable pitch (forward/back)
            )
            : manual3DRotation
        
        // Add subtle parallax pan effect (only for stationary grids)
        // Only horizontal pan since we disabled vertical rotation
        let pan = (useGyro && !disablePan)
            ? CGSize(
                width: gyro.normalizedRotation.roll * 25 * gyroSensitivity,   // Horizontal pan
                height: 0  // Disable vertical pan
            )
            : .zero
        
        return self
            .offset(x: pan.width, y: pan.height)
            .rotation3DEffect(
                .degrees(rotation.width),  // Only Y-axis rotation (roll)
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 1 / perspectiveDepth
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: rotation)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: pan)
    }
}


#Preview {
    Text("Enhanced Radar")
        .sheet(isPresented: .constant(true)) {
            RadioSheetView()
        }
}
