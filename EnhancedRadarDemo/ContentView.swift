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
    
    @State private var liveTranscript: [TranscriptLine] = []
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
                            .onChange(of: liveTranscript.count) { _, _ in
                                withAnimation(.easeOut(duration: 0.35)) {
                                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),   // hide at very top
                                    .init(color: .white, location: 0.62),  // fade-in complete by 12%
                                    .init(color: .white, location: 1.0)    // fully visible below
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .onAppear {
                            // Show an initial line immediately so the UI never appears empty
                            feedTimer?.invalidate()
                            if !sampleTranscript.isEmpty {
                                liveTranscript = [sampleTranscript[0]]
                                feedIndex = 1 % sampleTranscript.count
                            } else {
                                liveTranscript = []
                                feedIndex = 0
                            }
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
                                HStack {
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
                                        HStack(alignment: .top) {
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
                    .init(color: .clear, location: 0.3),
                    
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

struct GlassBar: View {
    var height: CGFloat = 84   // how tall the blur zone is

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)        // Frosted blur
            .frame(height: height)
            .overlay {                        // Gloss highlight
                LinearGradient(
                    colors: [.white.opacity(0.35), .white.opacity(0.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .blendMode(.plusLighter)
            }
            .overlay {                        // Soft rim
                Rectangle()
                    .stroke(.white.opacity(0.25), lineWidth: 0.75)
                    .blur(radius: 0.5)
            }
            // Feather the glass so it fades out into clear content below
            .mask {
                LinearGradient(stops: [
                    .init(color: .white, location: 0.0),
                    .init(color: .white, location: 0.7),
                    .init(color: .clear, location: 1.0)
                ], startPoint: .top, endPoint: .bottom)
            }
            .compositingGroup()
            .allowsHitTesting(false)
    }
}


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
