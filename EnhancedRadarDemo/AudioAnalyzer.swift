//
//  AudioAnalyzer.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI
import Combine
import AVFoundation
import Accelerate

// MARK: - Analyzer
final class AudioAnalyzer: ObservableObject {
    static let shared = AudioAnalyzer()
    @Published private(set) var spectrum: [Float] = Array(repeating: 0, count: 64)
    @Published private(set) var level: Float = 0

    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private let engine = AVAudioEngine()
    private let fftSize: vDSP_Length = 1024
    private let smoothing: Float = 0.65
    private let levelSmoothing: Float = 0.8

    private var window: [Float] = []
    private var isRunning = false
    private var idleTimer: Timer?

    private init() {
        window = vDSP.window(ofType: Float.self,
                             usingSequence: .hanningDenormalized,
                             count: Int(fftSize),
                             isHalfWindow: false)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Avoid touching audio session/engine in SwiftUI previews – they crash.
        if Self.isPreview {
            self.fakeIdleAnimation()
            return
        }

        if #available(iOS 17, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    if granted {
                        self.configureEngine()
                    } else {
                        self.fakeIdleAnimation()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    if granted {
                        self.configureEngine()
                    } else {
                        self.fakeIdleAnimation()
                    }
                }
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        idleTimer?.invalidate()
        idleTimer = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    /// If you already have an AVAudioEngine with a mixer/player,
    /// call this and install the tap on *your* node instead of mic input.
    func attachTap(to node: AVAudioNode, bus: AVAudioNodeBus = 0) throws {
        guard !engine.isRunning else { return }
        node.installTap(onBus: bus, bufferSize: AVAudioFrameCount(fftSize), format: node.outputFormat(forBus: bus)) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }
    }

    private func configureEngine() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP])
        try? session.setActive(true)

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }
        do {
            try engine.start()
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.fakeIdleAnimation()
            }
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        let frameCount = Int(buffer.frameLength)
        if frameCount <= 0 { return }

        // Copy samples and apply a Hann window to reduce flicker
        var samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        if samples.count >= window.count {
            // Use the first window.count samples (keeps CPU low on big buffers)
            let n = window.count
            var slice = Array(samples[0..<n])
            vDSP.multiply(slice, window, result: &slice)
            samples = slice
        } else {
            // If buffer is smaller than our window, just multiply what we have
            vDSP.multiply(samples, Array(window.prefix(samples.count)), result: &samples)
        }

        // Take absolute value as a rough energy estimate in time-domain
        var absSamples = [Float](repeating: 0, count: samples.count)
        vDSP.absolute(samples, result: &absSamples)

        // Compute a crude amplitude level for tape-style visualizers
        var meanAbs: Float = 0
        meanAbs = vDSP.mean(absSamples)
        // Normalize roughly to [0,1]
        let rawLevel = min(1, meanAbs * 2)

        // Downsample into N bars by taking the max of each segment
        let barCount = spectrum.count
        let binSize = max(1, absSamples.count / barCount)
        var bars = [Float](repeating: 0, count: barCount)
        var idx = 0
        for i in 0..<barCount {
            let start = idx
            let end = min(start + binSize, absSamples.count)
            if start < end {
                let segment = absSamples[start..<end]
                bars[i] = segment.max() ?? 0
            } else {
                bars[i] = 0
            }
            idx += binSize
        }

        // Normalize roughly to [0,1]
        let peak = (absSamples.max() ?? 1)
        if peak > 0.0001 {
            for i in 0..<bars.count { bars[i] = min(1, bars[i] / peak) }
        }

        // Smooth & publish on main thread
        DispatchQueue.main.async {
            self.level = max(rawLevel, self.level * self.levelSmoothing + rawLevel * (1 - self.levelSmoothing))
            for i in 0..<barCount {
                let prev = self.spectrum[i]
                self.spectrum[i] = max(bars[i], prev * self.smoothing + bars[i] * (1 - self.smoothing))
            }
        }
    }

    private func fakeIdleAnimation() {
        // Demo: Smooth scrolling tape recorder visualization
        idleTimer?.invalidate()
        
        // State for generating audio patterns
        var isTransmitting = false
        var nextTransmission = Date().addingTimeInterval(Double.random(in: 0.5...1.5))
        var currentPattern: [Float] = []
        var patternIndex = 0
        var frameCounter = 0
        
        // Generate audio patterns
        let createPattern: () -> [Float] = {
            let patterns: [[Float]] = [
                // Short burst
                [0.4, 0.7, 0.9, 0.7, 0.4],
                // Double peak
                [0.6, 0.9, 0.6, 0.3, 0.6, 0.9, 0.6],
                // Wave
                [0.3, 0.5, 0.7, 0.9, 0.8, 0.6, 0.4, 0.2],
                // Radio chatter
                [0.8, 0.4, 1.0, 0.3, 0.9, 0.5, 1.0, 0.4],
                // Ascending
                [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
            ]
            return patterns.randomElement() ?? [0.5]
        }
        
        let fps = 1.0 / 60.0
        
        idleTimer = Timer.scheduledTimer(withTimeInterval: fps, repeats: true) { [weak self] t in
            guard let self, self.isRunning else { t.invalidate(); return }
            let now = Date()
            
            // Shift spectrum data every few frames to create scrolling effect
            frameCounter += 1
            if frameCounter % 2 == 0 {  // Shift every 2 frames for smoother motion
                let n = self.spectrum.count
                
                // Shift all values left
                for i in 0..<(n-1) {
                    self.spectrum[i] = self.spectrum[i+1]
                }
                
                // Generate new value for the rightmost bar
                var newValue: Float = 0
                
                if isTransmitting {
                    // Currently transmitting a pattern
                    if patternIndex < currentPattern.count {
                        newValue = currentPattern[patternIndex]
                        // Add slight variation
                        newValue += Float.random(in: -0.05...0.05)
                        newValue = max(0, min(1, newValue))
                        
                        // Move to next pattern value every 3 shifts
                        if frameCounter % 6 == 0 {
                            patternIndex += 1
                        }
                    } else {
                        // Pattern ended
                        isTransmitting = false
                        newValue = Float.random(in: 0...0.02)
                        // Schedule next transmission
                        let gap = Double.random(in: 1.5...4.0)
                        nextTransmission = now.addingTimeInterval(gap)
                    }
                } else {
                    // Complete silence - no noise
                    newValue = 0
                    
                    if now >= nextTransmission {
                        // Start new transmission
                        isTransmitting = true
                        currentPattern = createPattern()
                        patternIndex = 0
                    }
                }
                
                // Add new value at the end (right side)
                self.spectrum[n-1] = newValue
            }
            
            // Update overall level
            self.level = isTransmitting ? 0.4 : 0.0
        }
    }

    deinit {
        stop()
    }
}

// MARK: - Bar visualizer
struct AudioVisualizerView: View {
    @StateObject private var analyzer = AudioAnalyzer.shared
    var barCount: Int = 56
    var barCorner: CGFloat = 0
    var height: CGFloat = 28
    var verticalScale: CGFloat = 1
    var spacing: CGFloat = 2
    
    @State private var scrollingBars: [(x: CGFloat, height: CGFloat, id: Int)] = []
    @State private var nextBarID = 0
    @State private var lastClusterTime = Date()
    @State private var animationCycle: Int = 0
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = height
            let barWidth: CGFloat = 2
            
            // Draw center reference line (2px thick, BLACK)
            let centerY = h / 2
            let lineRect = CGRect(x: 0, y: centerY - 1, width: w, height: 2)
            context.fill(Path(lineRect), with: .color(.black))
            
            // Draw all scrolling bars with edge fade animations
            for bar in scrollingBars {
                // Only draw if visible
                if bar.x >= -barWidth && bar.x <= w {
                    // Calculate height fade based on position
                    var heightMultiplier: CGFloat = 1.0
                    let rightFadeWidth: CGFloat = 25 // larger fade zone on right
                    let leftFadeWidth: CGFloat = 35   // much earlier fade on left
                    
                    // Fade in from right edge (reduce height) - starts offscreen
                    if bar.x > w - rightFadeWidth {
                        heightMultiplier = max(0, (w - bar.x) / rightFadeWidth)
                    }
                    // Fade out at left edge (reduce height) - starts earlier
                    else if bar.x < leftFadeWidth {
                        heightMultiplier = max(0, bar.x / leftFadeWidth)
                    }
                    
                    // Apply height reduction for fade effect
                    let fadedHeight = bar.height * heightMultiplier
                    
                    // Upper bar (black color, faded height)
                    let upperRect = CGRect(
                        x: bar.x,
                        y: centerY - fadedHeight/2 - 1,
                        width: barWidth,
                        height: fadedHeight/2
                    )
                    context.fill(Path(upperRect), with: .color(.black))
                    
                    // Lower bar (black color, faded height)
                    let lowerRect = CGRect(
                        x: bar.x,
                        y: centerY + 1,
                        width: barWidth,
                        height: fadedHeight/2
                    )
                    context.fill(Path(lowerRect), with: .color(.black))
                }
            }
        }
        .frame(height: height)
        .onReceive(timer) { _ in
            let w: CGFloat = 350 // approximate view width (avoid deprecated UIScreen.main)
            let scrollSpeed: CGFloat = 2.0
            
            // Move all existing bars left
            for i in scrollingBars.indices {
                scrollingBars[i].x -= scrollSpeed
            }
            
            // Remove bars that are completely off screen
            scrollingBars.removeAll { $0.x < -10 }
            
            // Create interesting cluster shapes
            func createCluster(startX: CGFloat, baseHeight: CGFloat) {
                let shapes = ["bell", "wave", "double_peak", "burst"] // Restored wave pattern
                let shape = shapes.randomElement() ?? "bell"
                let clusterSize = Int.random(in: 9...15) // Even wider clusters

                // Precompute parameters for shapes that need consistency across the cluster
                let multiWavePartials: [(freq: CGFloat, amp: CGFloat, phase: CGFloat)] = [
                    (1.0, 1.0, CGFloat.random(in: 0...(2 * .pi))),   // fundamental
                    (2.0, 0.45, CGFloat.random(in: 0...(2 * .pi))),  // 2nd harmonic
                    (3.0, 0.25, CGFloat.random(in: 0...(2 * .pi)))   // 3rd harmonic
                ]
                let amDepth: CGFloat = CGFloat.random(in: 0.05...0.22)  // amplitude modulation depth
                let amFreq:  CGFloat = CGFloat.random(in: 0.4...1.4)    // amplitude modulation frequency (cycles across cluster)
                let envSharpness: CGFloat = CGFloat.random(in: 3.0...5.0) // controls attack/decay envelope sharpness

                for i in 0..<clusterSize {
                    let xOffset = CGFloat(i) * 5.0 // More spacing between bars
                    let progress = CGFloat(i) / CGFloat(clusterSize - 1) // 0 to 1

                    var heightMultiplier: CGFloat = 1.0

                    switch shape {
                    case "bell":
                        // Bell curve - high in middle, low at edges
                        let bellValue = exp(-pow((progress - 0.5) * 4, 2))
                        heightMultiplier = 0.4 + bellValue * 0.8 // Taller

                    case "wave":
                        // Composite of multiple partials + gentle amplitude modulation and bell envelope
                        let sumAmp = multiWavePartials.reduce(0) { $0 + $1.amp }
                        let composite = multiWavePartials.reduce(CGFloat(0)) { acc, p in
                            acc + p.amp * sin(progress * .pi * 2 * p.freq + p.phase)
                        }
                        // Normalize sum of sines (from [-sumAmp, +sumAmp]) to [0, 1]
                        var normalized = (composite / max(0.0001, sumAmp) + 1) * 0.5

                        // Bell-like envelope for natural attack/decay across the cluster width
                        let envelope = exp(-pow((progress - 0.5) * envSharpness, 2))

                        // Light amplitude modulation to avoid a static look
                        let am = 1 + amDepth * sin(progress * .pi * 2 * amFreq)

                        normalized = normalized * (0.55 + 0.45 * envelope) * am

                        // Sprinkle a touch of noise
                        normalized += CGFloat.random(in: -0.03...0.03)

                        // Clamp and assign
                        heightMultiplier = max(0.0, min(1.4, normalized))

                    case "double_peak":
                        // Two peaks
                        let peak1 = exp(-pow((progress - 0.25) * 6, 2))
                        let peak2 = exp(-pow((progress - 0.75) * 6, 2))
                        heightMultiplier = 0.3 + max(peak1, peak2) * 0.9 // Taller

                    case "burst":
                        // Random spiky burst
                        let basePattern = exp(-pow((progress - 0.5) * 3, 2))
                        let spike = CGFloat.random(in: 0.8...1.4) // Taller spikes
                        heightMultiplier = basePattern * spike

                    default:
                        heightMultiplier = CGFloat.random(in: 0.7...1.5) // Taller default
                    }

                    let clusterBar = (
                        x: startX + xOffset,
                        height: baseHeight * heightMultiplier,
                        id: nextBarID
                    )
                    scrollingBars.append(clusterBar)
                    nextBarID += 1
                }
            }
            
            let now = Date()
            let timeSinceLastCluster = now.timeIntervalSince(lastClusterTime)
            
            // Infinite looping animation with predictable patterns
            let predefinedPatterns: [(timing: Double, heightMultiplier: CGFloat)] = [
                (0.0, 0.7),   // First cluster
                (1.5, 0.9),   // Second cluster
                (3.2, 0.5),   // Third cluster
                (5.0, 1.0),   // Fourth cluster
                (7.2, 0.6),   // Fifth cluster
                (8.5, 0.8),   // Sixth cluster
                (10.5, 0.4),  // Seventh cluster
                (12.0, 0.9)   // Eighth cluster - then loop
            ]
            
            // Calculate cycle position (12 second loop)
            let cycleLength: Double = 12.0
            let currentTime = now.timeIntervalSinceReferenceDate
            let cycleTime = currentTime.truncatingRemainder(dividingBy: cycleLength)
            
            // Check if we should spawn a cluster based on the pattern
            for pattern in predefinedPatterns {
                let timeDiff = abs(cycleTime - pattern.timing)
                if timeDiff < 0.05 && timeSinceLastCluster > 0.3 { // Within 50ms of pattern time
                    let baseHeight = pattern.heightMultiplier * height * 0.8
                    createCluster(startX: w + 20, baseHeight: baseHeight)
                    lastClusterTime = now
                    break
                }
            }
        }
        .onAppear {
            analyzer.start()
            scrollingBars = []
        }
        .onDisappear {
            analyzer.stop()
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Scrolling tape-style visualizer
struct TapeVisualizerView: View {
    @StateObject private var analyzer = AudioAnalyzer.shared
    var height: CGFloat = 28
    var lineWidth: CGFloat = 2
    var speed: CGFloat = 140 // points per second
    var smoothing: CGFloat = 0.5 // visual smoothing of samples
    var capacity: Int = 600

    @State private var samples: [CGFloat] = []
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { context, size in
            let h = height
            let mid = h / 2
            let amp: CGFloat = h * 0.42
            var path = Path()

            if samples.isEmpty {
                // nothing yet
            } else {
                let dx = size.width / CGFloat(max(samples.count - 1, 1))
                path.move(to: CGPoint(x: 0, y: mid - samples[0] * amp))
                var yPrev = mid - samples[0] * amp
                for i in 1..<samples.count {
                    let y = mid - samples[i] * amp
                    // simple smoothing to avoid jaggies
                    let ySm = yPrev * (1 - smoothing) + y * smoothing
                    let x = CGFloat(i) * dx
                    path.addLine(to: CGPoint(x: x, y: ySm))
                    yPrev = ySm
                }
            }

            context.stroke(path, with: .foreground, lineWidth: lineWidth)
        }
        .frame(height: height)
        .onReceive(timer) { _ in
            // Append current level and keep buffer size consistent with view width
            let lvl = CGFloat(min(max(analyzer.level, 0), 1)) * 2 - 1 // map 0..1 to -1..1
            samples.append(lvl)
            if samples.count > capacity { samples.removeFirst(samples.count - capacity) }
        }
        .onAppear { analyzer.start() }
        .onDisappear { analyzer.stop() }
        .accessibilityHidden(true)
    }
}

// MARK: - Sweeping blip visualizer (one end to the other)
struct SweepVisualizerView: View {
    var height: CGFloat = 24
    var blipWidth: CGFloat = 4
    var corner: CGFloat = 2
    var sweepDuration: Double = 0.8          // seconds to sweep across
    var gapRange: ClosedRange<Double> = 3...7 // seconds of silence between sweeps
    var trail: Int = 10                       // how many trailing echoes to draw

    @State private var phaseIsSweeping = false
    @State private var progress: CGFloat = 0   // 0..1 across width
    @State private var nextStart = Date()
    @State private var lastTick = Date()
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = height

            guard phaseIsSweeping else { return }

            // Draw the active blip and a fading trail behind it
            let x = progress * w
            let blipRect = CGRect(x: x - blipWidth/2, y: (h*0.15), width: blipWidth, height: h*0.70)
            let blipPath = Path(roundedRect: blipRect, cornerRadius: corner)
            context.fill(blipPath, with: .foreground)

            // Trailing echoes (decreasing opacity / expanding slightly)
            if trail > 0 {
                for i in 1...trail {
                    let t = CGFloat(i)
                    let decay = max(0, 1 - t / CGFloat(trail + 1))
                    let tx = x - t * (w * 0.008) // trail spacing
                    if tx + blipWidth < 0 { break }
                    let rect = CGRect(x: tx - blipWidth/2,
                                      y: (h*0.15) + t*0.2,
                                      width: blipWidth,
                                      height: h*0.70 - t*0.4)
                    let path = Path(roundedRect: rect, cornerRadius: corner)
                    // GraphicsContext has no save/restore; preserve and restore opacity manually
                    let prevOpacity = context.opacity
                    context.opacity = decay * 0.35
                    context.fill(path, with: .foreground)
                    context.opacity = prevOpacity
                }
            }
        }
        .frame(height: height)
        .onReceive(timer) { _ in
            let now = Date()
            let dt = now.timeIntervalSince(lastTick)
            lastTick = now

            if phaseIsSweeping {
                if sweepDuration <= 0 {
                    progress = 1
                } else {
                    progress += CGFloat(dt / sweepDuration)
                }
                if progress >= 1 {
                    phaseIsSweeping = false
                    progress = 0
                    nextStart = now.addingTimeInterval(Double.random(in: gapRange))
                }
            } else {
                if now >= nextStart {
                    phaseIsSweeping = true
                    progress = 0
                }
            }
        }
    }
}
