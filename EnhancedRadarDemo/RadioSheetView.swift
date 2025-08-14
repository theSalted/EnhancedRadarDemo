//
//  RadioSheetView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//


import SwiftUI
import OSLog


struct Plane {
    enum State {
        case takeoff, landing, taxing
        
        func tiltAngle() -> CGFloat {
            switch self {
                
            case .takeoff:
                13
            case .landing:
                -13
            case .taxing:
                0
            }
        }
        
        func gridFlightState() -> AviationGridView.FlightState {
            switch self {
            case .takeoff:
                    .flight
            case .landing:
                    .flight
            case .taxing:
                    .taxing
            }
        }
        
        func velocity() -> CGSize {
            switch self {
            case .takeoff:
                return CGSize(width: 20, height: -10)  // Moving right and up (departing)
            case .landing:
                return CGSize(width: 20, height: 10)  // Moving left and down (arriving)
            case .taxing:
                return CGSize(width: 15, height: 0)     // Slow movement on ground
                
            }
        }
    }
    let imageName: String
    let state: State
    let offset: CGFloat
}

struct RadioSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var liveTranscript: [TranscriptLine] = [
        TranscriptLine(speaker: "ATC", text: "Delta 1008, La Guardia Tower, contact New York Departure.")
    ]
    
    @State private var feedIndex: Int = 0
    @State private var feedTimer: Timer? = nil
    
    // Timer for automatic plane switching
    @State private var planeTimer: Timer? = nil
    
    // Current plane being tracked by ATC
    @State private var currentPlane: Plane = Plane(imageName: "DeltaPlane", state: .takeoff, offset: 0)
    
    // Animation states for plane transitions
    @State private var planeOffset: CGSize = .zero
    @State private var planeOpacity: Double = 1.0
    @State private var planeScale: CGFloat = 1.0
    @State private var isTransitioning: Bool = false
    
    // Cached values to prevent constant InfiniteGridView recreation
    @State private var cachedVelocityX: CGFloat = 20
    @State private var cachedVelocityY: CGFloat = -10
    @State private var cachedFlightState: AviationGridView.FlightState = .flight
    
    // All possible plane combinations (2 airlines × 3 states = 6 permutations)
    private let planeCombos: [Plane] = [
        Plane(imageName: "DeltaPlane", state: .takeoff, offset: 0),
        Plane(imageName: "DeltaPlane", state: .landing, offset: 0),
        Plane(imageName: "DeltaPlane", state: .taxing, offset: 60),
        Plane(imageName: "UnitedPlane", state: .takeoff, offset: -60),
        Plane(imageName: "UnitedPlane", state: .landing, offset: -60),
        Plane(imageName: "UnitedPlane", state: .taxing, offset: -40)
    ]
    
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

    // Switch to a random different plane with smooth animations
    private func switchToNewPlane() {
        guard !isTransitioning else { return }
        
        // Pick a random plane different from current
        let availablePlanes = planeCombos.filter { $0.imageName != currentPlane.imageName || $0.state != currentPlane.state }
        guard let newPlane = availablePlanes.randomElement() else { return }
        
        isTransitioning = true
        
        // Calculate realistic departure position based on current plane's operation
        let departureHeight: CGFloat = {
            switch currentPlane.state {
            case .takeoff:
                return -100  // Fly out high (climbing after takeoff)
            case .landing:
                return 0     // Fly out at center level
            case .taxing:
                return 100   // Fly out low (ground level)
            }
        }()
        
        // Calculate realistic arrival position based on new plane's operation
        let arrivalHeight: CGFloat = {
            switch newPlane.state {
            case .takeoff:
                return 100   // Arrive low (preparing for takeoff from ground)
            case .landing:
                return -100  // Arrive high (on approach from altitude)
            case .taxing:
                return 0     // Arrive at center level (taxiing)
            }
        }()
        
        // Phase 1: Current plane flies out to left edge (departing)
        withAnimation(.easeIn(duration: 0.3)) {
            planeOffset = CGSize(width: -400, height: departureHeight)
            planeOpacity = 0.15  // Fade to partial opacity for depth perception
            planeScale = 0.3  // Scale down as it flies away
        }
        
        // Phase 2: After current plane flies out, update plane and grid, then fly new plane in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Update to new plane (happens while invisible)
            currentPlane = newPlane
            
            // Position new plane at right edge, ready to fly in
            planeOffset = CGSize(width: 400, height: arrivalHeight)
            planeOpacity = 0.25  // Start with partial opacity for depth perception
            planeScale = 0.3  // Start small (far away)
            
            // Phase 3: New plane flies in right to left (arriving)
            withAnimation(.easeOut(duration: 0.3)) {
                planeOffset = .zero  // Fly to center position
                planeOpacity = 1.0
                planeScale = 1.0  // Scale up to full size as it approaches
            }
            
            // Mark transition complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTransitioning = false
            }
        }
    }
    
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
    
    // Schedule automatic plane switching at random 2-5 second intervals
    private func scheduleNextPlaneSwitch() {
        planeTimer?.invalidate()
        let delay = Double.random(in: 2.0...5.0)
        planeTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            DispatchQueue.main.async {
                switchToNewPlane()
                // Chain the next plane switch
                scheduleNextPlaneSwitch()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AviationGridView(
                    spacing: 10,
                    majorEvery: 1,
                    color: .white.opacity(1),
                    majorColor: .white.opacity(0.25),
                    lineWidth: 0.01,
                    majorLineWidth: 0.1,
                    velocityX: cachedVelocityX,
                    velocityY: cachedVelocityY,
                    allowsCameraControl: false,
                    flightState: $cachedFlightState,
                    animationDuration: 0.6
                )
                .offset(y: -400)
                .ignoresSafeArea()
                .onChange(of: currentPlane.state) { oldState, newState in
                    // Update cached values only when plane state actually changes
                    let newVelocity = newState.velocity()
                    cachedVelocityX = newVelocity.width
                    cachedVelocityY = newVelocity.height
                    cachedFlightState = newState.gridFlightState()
                }
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
                    Image(currentPlane.imageName)
                        .resizable()
                        .rotationEffect(.degrees(currentPlane.state.tiltAngle()))
                        .scaleEffect(planeScale)
                        .offset(x: planeOffset.width, y: currentPlane.offset + planeOffset.height)
                        .opacity(planeOpacity)
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
                            // Initialize cached values with current plane state
                            let initialVelocity = currentPlane.state.velocity()
                            cachedVelocityX = initialVelocity.width
                            cachedVelocityY = initialVelocity.height
                            cachedFlightState = currentPlane.state.gridFlightState()
                            
                            // Show an initial line immediately so the UI never appears empty
                            // Begin the randomized 3–5s feed loop
                            scheduleNextFeed()
                            // Begin automatic plane switching
                            scheduleNextPlaneSwitch()
                        }
                        .onDisappear {
                            feedTimer?.invalidate()
                            planeTimer?.invalidate()
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
