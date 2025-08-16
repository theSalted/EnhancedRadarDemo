//
//  InfiniteGridView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/13/25.
//

import SwiftUI
import SceneKit

struct InfiniteGridView: View, Equatable {
    // Grid properties
    var spacing: CGFloat = 16
    var majorEvery: Int = 4
    var color: Color = .secondary.opacity(1)
    var majorColor: Color = .secondary.opacity(1)
    var lineWidth: CGFloat = 0.5
    var majorLineWidth: CGFloat = 1
    
    // Velocity properties (points per second)
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    
    // Camera control
    var allowsCameraControl: Bool = false
    
    // Gyro control (nil = disabled completely, CGFloat = sensitivity multiplier)
    var gyroSensitivityX: CGFloat? = nil
    var gyroSensitivityY: CGFloat? = nil
    
    // Manual camera rotation (nil = no manual rotation, CGFloat = rotation in degrees)
    var cameraRotationX: CGFloat? = nil  // Pitch (up/down)
    var cameraRotationY: CGFloat? = nil  // Yaw (left/right)
    var cameraRotationZ: CGFloat? = nil  // Roll (tilt)
    
    // Animation timing for manual rotations
    var manualRotationAnimationDuration: Double = 2.0
    
    // Animation-friendly spacing updates
    var animateSpacingChanges: Bool = false
    
    init(
        spacing: CGFloat = 16,
        majorEvery: Int = 4,
        color: Color = .secondary.opacity(1),
        majorColor: Color = .secondary.opacity(1),
        lineWidth: CGFloat = 0.5,
        majorLineWidth: CGFloat = 1,
        velocityX: CGFloat = 0,
        velocityY: CGFloat = 0,
        allowsCameraControl: Bool = false,
        gyroSensitivityX: CGFloat? = nil,
        gyroSensitivityY: CGFloat? = nil,
        cameraRotationX: CGFloat? = nil,
        cameraRotationY: CGFloat? = nil,
        cameraRotationZ: CGFloat? = nil,
        manualRotationAnimationDuration: Double = 2.0,
        animateSpacingChanges: Bool = false
    ) {
        let hasVelocity = velocityX != 0 || velocityY != 0
        let hasGyro = gyroSensitivityX != nil || gyroSensitivityY != nil
        
        self.spacing = spacing
        self.majorEvery = majorEvery
        self.color = color
        self.majorColor = majorColor
        self.lineWidth = lineWidth
        self.majorLineWidth = majorLineWidth
        self.velocityX = velocityX
        self.velocityY = velocityY
        self.allowsCameraControl = allowsCameraControl
        self.gyroSensitivityX = hasVelocity ? nil : gyroSensitivityX
        self.gyroSensitivityY = hasVelocity ? nil : gyroSensitivityY
        self.cameraRotationX = cameraRotationX
        self.cameraRotationY = cameraRotationY
        self.cameraRotationZ = cameraRotationZ
        self.manualRotationAnimationDuration = manualRotationAnimationDuration
        self.animateSpacingChanges = animateSpacingChanges
        
        if hasVelocity && hasGyro {
            print("Warning: Gyro disabled because velocity is active. Gyro and velocity are mutually exclusive.")
        }
    }
    
    var body: some View {
        TransparentSceneView(
            spacing: spacing,
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
            cameraRotationX: cameraRotationX,
            cameraRotationY: cameraRotationY,
            cameraRotationZ: cameraRotationZ,
            manualRotationAnimationDuration: manualRotationAnimationDuration,
            animateSpacingChanges: animateSpacingChanges
        )
        .ignoresSafeArea()
    }
    
    private func createGridScene() -> SCNScene {
        let scene = SCNScene()
        
        // Make scene background transparent
        scene.background.contents = UIColor.clear
        
        // Create grid geometry
        let gridNode = createGridNode()
        gridNode.name = "gridNode"
        scene.rootNode.addChildNode(gridNode)
        
        // Set up camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60  // Standard field of view
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func createGridNode() -> SCNNode {
        let gridNode = SCNNode()
        
        // Convert SwiftUI points to SceneKit units for accurate spacing
        // With camera at z=10 and FOV=60°, this scaling gives us accurate point-to-visual mapping
        let pointToSceneKitScale: Float = 0.1
        
        // Grid dimensions - efficient size since camera moves, not grid
        let gridSize: Float = 200  // Adjusted for the scaling
        let step = Float(spacing) * pointToSceneKitScale
        let majorStep = Int(majorEvery)
        
        // Create minor lines
        let minorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: false
        )
        
        // Create major lines
        let majorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: true
        )
        
        gridNode.addChildNode(minorLines)
        gridNode.addChildNode(majorLines)
        
        return gridNode
    }
    
    private func createGridLines(gridSize: Float, step: Float, majorStep: Int, isMajor: Bool) -> SCNNode {
        let linesNode = SCNNode()
        let vertices = NSMutableArray()
        let indices = NSMutableArray()
        var currentIndex: Int32 = 0
        
        let halfSize = gridSize / 2
        let numLines = Int(gridSize / step)
        
        // Create vertical lines centered around origin
        let startIndex = -numLines/2
        let endIndex = numLines/2
        
        for i in startIndex...endIndex {
            let shouldDraw = isMajor ? (i % majorStep == 0) : (i % majorStep != 0)
            guard shouldDraw else { continue }
            
            let x = Float(i) * step
            
            // Line from bottom to top
            vertices.add(NSValue(scnVector3: SCNVector3(x, -halfSize, 0)))
            vertices.add(NSValue(scnVector3: SCNVector3(x, halfSize, 0)))
            
            indices.add(NSNumber(value: currentIndex))
            indices.add(NSNumber(value: currentIndex + 1))
            currentIndex += 2
        }
        
        // Create horizontal lines centered around origin
        for i in startIndex...endIndex {
            let shouldDraw = isMajor ? (i % majorStep == 0) : (i % majorStep != 0)
            guard shouldDraw else { continue }
            
            let y = Float(i) * step
            
            // Line from left to right
            vertices.add(NSValue(scnVector3: SCNVector3(-halfSize, y, 0)))
            vertices.add(NSValue(scnVector3: SCNVector3(halfSize, y, 0)))
            
            indices.add(NSNumber(value: currentIndex))
            indices.add(NSNumber(value: currentIndex + 1))
            currentIndex += 2
        }
        
        // Create geometry source
        let vertexData = Data(bytes: vertices.map { ($0 as! NSValue).scnVector3Value }, count: vertices.count * MemoryLayout<SCNVector3>.size)
        let vertexSource = SCNGeometrySource(data: vertexData, semantic: .vertex, vectorCount: vertices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size)
        
        // Create geometry element
        let indexData = Data(bytes: indices.map { ($0 as! NSNumber).int32Value }, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<Int32>.size)
        
        // Create geometry
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        
        // Create material
        let material = SCNMaterial()
        let lineColor = isMajor ? majorColor : color
        material.diffuse.contents = UIColor(lineColor)
        material.lightingModel = .constant  // Unlit material
        material.isDoubleSided = true
        material.transparency = 1.0
        geometry.materials = [material]
        
        linesNode.geometry = geometry
        return linesNode
    }
}

struct TransparentSceneView: UIViewRepresentable {
    let spacing: CGFloat
    let majorEvery: Int
    let color: Color
    let majorColor: Color
    let lineWidth: CGFloat
    let majorLineWidth: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let allowsCameraControl: Bool
    let gyroSensitivityX: CGFloat?
    let gyroSensitivityY: CGFloat?
    let cameraRotationX: CGFloat?
    let cameraRotationY: CGFloat?
    let cameraRotationZ: CGFloat?
    let manualRotationAnimationDuration: Double
    let animateSpacingChanges: Bool
    
    @StateObject private var gyro = GyroService.shared
    
    // Track previous rotation values to detect changes
    @State private var previousRotationX: CGFloat? = nil
    @State private var previousRotationY: CGFloat? = nil
    @State private var previousRotationZ: CGFloat? = nil
    
    // Track previous geometry values to detect changes
    @State private var previousSpacing: CGFloat = 0
    @State private var previousMajorEvery: Int = 0
    
    
    func makeUIView(context: Context) -> SCNView {
        let coordinator = context.coordinator
        let scnView = SCNView()
        scnView.allowsCameraControl = allowsCameraControl  // Use the parameter
        scnView.backgroundColor = UIColor.clear
        scnView.isOpaque = false
        scnView.antialiasingMode = .multisampling4X
        
        // Additional settings to reduce flickering and double rendering
        scnView.preferredFramesPerSecond = 60
        scnView.autoenablesDefaultLighting = false  // Disable automatic lighting
        scnView.allowsCameraControl = allowsCameraControl
        
        // Create the scene once
        let scene = createGridScene()
        scnView.scene = scene
        
        // Initialize camera rotation immediately to prevent double rendering
        if let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
            var rotationX: Float = 0
            var rotationY: Float = 0
            var rotationZ: Float = 0
            
            if let rotX = cameraRotationX {
                rotationX = Float(rotX * .pi / 180.0)
            }
            if let rotY = cameraRotationY {
                rotationY = Float(rotY * .pi / 180.0)
            }
            if let rotZ = cameraRotationZ {
                rotationZ = Float(rotZ * .pi / 180.0)
            }
            
            // Set initial rotation without animation to prevent double rendering
            cameraNode.eulerAngles = SCNVector3(rotationX, rotationY, rotationZ)
        }
        
        // Initialize previous values
        DispatchQueue.main.async {
            self.previousRotationX = cameraRotationX
            self.previousRotationY = cameraRotationY
            self.previousRotationZ = cameraRotationZ
            self.previousSpacing = spacing
            self.previousMajorEvery = majorEvery
        }
        
        // Start gyro if any sensitivity is set AND no velocity is active (but don't double-start in updateUIView)
        let hasVelocity = velocityX != 0 || velocityY != 0
        if (gyroSensitivityX != nil || gyroSensitivityY != nil) && !hasVelocity {
            gyro.requestStart()
            coordinator.didStartGyro = true
        }
        
        return scnView
    }
    
    class Coordinator {
        var didStartGyro: Bool = false
        
        deinit {
            // Critical: Stop gyro when coordinator is deallocated
            if didStartGyro && GyroService.shared.isActive {
                GyroService.shared.requestStop()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        // Cleanup when view is destroyed - this is critical for preventing gyro leaks
        if coordinator.didStartGyro {
            GyroService.shared.requestStop()
        }
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene,
              let gridNode = scene.rootNode.childNode(withName: "gridNode", recursively: true) else {
            return
        }
        
        // Update camera control setting
        uiView.allowsCameraControl = allowsCameraControl
        
        // Update grid geometry only if spacing or majorEvery actually changed
        let geometryChanged = (spacing != previousSpacing || majorEvery != previousMajorEvery)
        if geometryChanged {
            if animateSpacingChanges {
                // Use smooth transaction for spacing changes during animations
                SCNTransaction.begin()
                SCNTransaction.animationDuration = manualRotationAnimationDuration
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                updateGridGeometry(gridNode: gridNode)
                SCNTransaction.commit()
            } else {
                // Immediate update for non-animated changes
                updateGridGeometry(gridNode: gridNode)
            }
            DispatchQueue.main.async {
                self.previousSpacing = spacing
                self.previousMajorEvery = majorEvery
            }
        }
        
        // Update materials/colors (these are lightweight updates)
        updateGridMaterials(gridNode: gridNode)
        
        // Update gyro lifecycle based on sensitivity settings
        updateGyroLifecycle()
        
        // Update camera rotation only if manual rotation values changed or gyro is active
        let rotationChanged = (cameraRotationX != previousRotationX || 
                              cameraRotationY != previousRotationY || 
                              cameraRotationZ != previousRotationZ)
        let hasActiveGyro = (gyroSensitivityX != nil || gyroSensitivityY != nil) && gyro.isActive
        
        if rotationChanged || hasActiveGyro {
            updateCameraGyroTilt(scene: scene)
            
            // Update previous values
            DispatchQueue.main.async {
                self.previousRotationX = cameraRotationX
                self.previousRotationY = cameraRotationY
                self.previousRotationZ = cameraRotationZ
            }
        }
        
        // Update animation (velocity changes)
        updateGridAnimation(gridNode: gridNode, scene: scene)
    }
    
    private func updateGyroLifecycle() {
        let hasVelocity = velocityX != 0 || velocityY != 0
        
        // Stop gyro if both sensitivities are nil OR if velocity is active
        if (gyroSensitivityX == nil && gyroSensitivityY == nil) || hasVelocity {
            if gyro.isActive {
                gyro.requestStop()
            }
        }
        // Note: Starting is only handled in makeUIView to prevent multiple start calls
    }
    
    private func updateCameraGyroTilt(scene: SCNScene) {
        guard let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }),
              let camera = cameraNode.camera else { return }
        
        // Calculate rotation values from gyro
        var gyroRotationX: Float = 0
        var gyroRotationY: Float = 0
        let gyroRotationZ: Float = 0
        
        if let sensX = gyroSensitivityX, gyro.isActive {
            // Original: gyro.normalizedRotation.roll * 35 * gyroSensitivity (degrees)
            // normalizedRotation.roll is already -1 to 1, multiply by sensitivity and convert to radians
            let degrees = gyro.normalizedRotation.roll * sensX
            gyroRotationY = Float(degrees * .pi / 180.0)  // Convert degrees to radians for SceneKit
        }
        
        if let sensY = gyroSensitivityY, gyro.isActive {
            // Pitch rotation (forward/back tilt)
            let degrees = -gyro.normalizedRotation.pitch * sensY  // Negative for natural feel
            gyroRotationX = Float(degrees * .pi / 180.0)
        }
        
        // Add manual camera rotation values (if provided)
        var manualRotationX: Float = 0
        var manualRotationY: Float = 0
        var manualRotationZ: Float = 0
        
        if let rotX = cameraRotationX {
            manualRotationX = Float(rotX * .pi / 180.0)  // Convert degrees to radians
        }
        
        if let rotY = cameraRotationY {
            manualRotationY = Float(rotY * .pi / 180.0)
        }
        
        if let rotZ = cameraRotationZ {
            manualRotationZ = Float(rotZ * .pi / 180.0)
        }
        
        // Combine gyro and manual rotations
        let totalRotationX = gyroRotationX + manualRotationX
        let totalRotationY = gyroRotationY + manualRotationY
        let totalRotationZ = gyroRotationZ + manualRotationZ
        
        let targetRotation = SCNVector3(totalRotationX, totalRotationY, totalRotationZ)
        
        // Keep normal field of view for both flight and taxi modes
        let adjustedFOV: CGFloat = 60  // Standard field of view always
        
        // Always use SCNTransaction for smooth animation, but adjust duration based on source
        let hasActiveGyro = (gyroSensitivityX != nil || gyroSensitivityY != nil) && gyro.isActive
        
        SCNTransaction.begin()
        if hasActiveGyro {
            // Fast updates for gyro responsiveness
            SCNTransaction.animationDuration = 0.1
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        } else {
            // Use the provided animation duration for manual rotations
            SCNTransaction.animationDuration = manualRotationAnimationDuration
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        }
        cameraNode.eulerAngles = targetRotation
        camera.fieldOfView = adjustedFOV  // Apply perspective compensation
        SCNTransaction.commit()
    }
    
    private func updateGridAnimation(gridNode: SCNNode, scene: SCNScene) {
        gridNode.removeAllActions()
        
        // Handle camera gyro tilt (removing actions would conflict with gyro tilt)
        
        // Check if we have velocity movement for the grid
        let hasVelocity = velocityX != 0 || velocityY != 0
        
        if hasVelocity {
            let step = Float(spacing) * 0.1  // Grid spacing in SceneKit units
            
            // Animate the grid with smart wrapping that preserves major line pattern
            let moveAction = SCNAction.customAction(duration: 0.016) { node, elapsedTime in
                let currentPos = node.position
                
                // Calculate base velocity movement per frame
                let baseFrameMoveX = Float(self.velocityX) * 0.1 * 0.016
                let baseFrameMoveY = Float(self.velocityY) * 0.1 * 0.016
                
                // Combine velocity movement (gyro affects camera, not grid)
                let totalFrameMoveX = baseFrameMoveX
                let totalFrameMoveY = baseFrameMoveY
                
                // Apply movement
                let newX = currentPos.x + totalFrameMoveX
                let newY = currentPos.y + totalFrameMoveY
                
                // Smart wrapping: wrap to maintain major line alignment
                let majorStepSize = step * Float(self.majorEvery)
                
                // Wrap within major grid boundaries to preserve major line pattern
                let wrappedX = self.smartWrap(value: newX, stepSize: majorStepSize)
                let wrappedY = self.smartWrap(value: newY, stepSize: majorStepSize)
                
                node.position = SCNVector3(wrappedX, wrappedY, currentPos.z)
            }
            
            let infiniteAction = SCNAction.repeatForever(moveAction)
            gridNode.runAction(infiniteAction, forKey: "gridAnimation")
        }
    }
    
    private func smartWrap(value: Float, stepSize: Float) -> Float {
        // Wrap to the nearest major grid boundary to preserve major line pattern
        let wrapped = value.truncatingRemainder(dividingBy: stepSize)
        return wrapped >= 0 ? wrapped : wrapped + stepSize
    }
    
    private func updateGridGeometry(gridNode: SCNNode) {
        // Remove all child nodes and recreate geometry
        gridNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Recreate grid with current parameters
        let pointToSceneKitScale: Float = 0.1
        let gridSize: Float = 200
        let step = Float(spacing) * pointToSceneKitScale
        let majorStep = Int(majorEvery)
        
        // Create minor lines
        let minorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: false
        )
        
        // Create major lines
        let majorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: true
        )
        
        gridNode.addChildNode(minorLines)
        gridNode.addChildNode(majorLines)
    }
    
    private func updateGridMaterials(gridNode: SCNNode) {
        // Update colors for all child nodes
        func updateNodeMaterials(_ node: SCNNode, isMajor: Bool) {
            if let geometry = node.geometry,
               let material = geometry.materials.first {
                let lineColor = isMajor ? majorColor : color
                material.diffuse.contents = UIColor(lineColor)
            }
            
            // Recursively update child nodes
            for childNode in node.childNodes {
                updateNodeMaterials(childNode, isMajor: isMajor)
            }
        }
        
        // Update minor lines (first child)
        if gridNode.childNodes.count > 0 {
            updateNodeMaterials(gridNode.childNodes[0], isMajor: false)
        }
        
        // Update major lines (second child)
        if gridNode.childNodes.count > 1 {
            updateNodeMaterials(gridNode.childNodes[1], isMajor: true)
        }
    }
    
    private func createGridScene() -> SCNScene {
        let scene = SCNScene()
        
        // Make scene background transparent
        scene.background.contents = UIColor.clear
        
        // Create grid geometry
        let gridNode = createGridNode()
        gridNode.name = "gridNode"
        scene.rootNode.addChildNode(gridNode)
        
        // Set up camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func createGridNode() -> SCNNode {
        let gridNode = SCNNode()
        
        // Convert SwiftUI points to SceneKit units for accurate spacing
        let pointToSceneKitScale: Float = 0.1
        
        // Grid dimensions - efficient size since camera moves, not grid
        let gridSize: Float = 200
        let step = Float(spacing) * pointToSceneKitScale
        let majorStep = Int(majorEvery)
        
        // Create minor lines
        let minorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: false
        )
        
        // Create major lines
        let majorLines = createGridLines(
            gridSize: gridSize,
            step: step,
            majorStep: majorStep,
            isMajor: true
        )
        
        gridNode.addChildNode(minorLines)
        gridNode.addChildNode(majorLines)
        
        return gridNode
    }
    
    private func createGridLines(gridSize: Float, step: Float, majorStep: Int, isMajor: Bool) -> SCNNode {
        let linesNode = SCNNode()
        
        _ = gridSize / 2
        let numLines = Int(gridSize / step)
        
        // Calculate line thickness based on line width parameters
        let actualLineWidth = isMajor ? Float(majorLineWidth) : Float(lineWidth)
        let baseRadius = actualLineWidth * 0.05 // Convert points to SceneKit radius
        let cylinderRadius = max(baseRadius, 0.002) // Minimum radius to prevent jitter on very thin lines
        
        // Create material once for all lines with anti-aliasing
        let material = SCNMaterial()
        let lineColor = isMajor ? majorColor : color
        material.diffuse.contents = UIColor(lineColor)
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.transparency = 1.0
        
        // Anti-aliasing settings for thin lines  
        material.fillMode = .fill
        material.cullMode = .back
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        
        // Prevent double rendering by ensuring proper blending
        material.blendMode = .alpha
        
        // Create vertical lines centered around origin
        let startIndex = -numLines/2
        let endIndex = numLines/2
        
        for i in startIndex...endIndex {
            let x = Float(i) * step
            
            // Calculate major line based on world position, not array index, to maintain pattern during wrapping
            let worldGridX = Int(round(x / step))
            let shouldDraw = isMajor ? (worldGridX % majorStep == 0) : (worldGridX % majorStep != 0)
            guard shouldDraw else { continue }
            
            // Create vertical cylinder line with higher resolution for smoother edges
            let verticalCylinder = SCNCylinder(radius: CGFloat(cylinderRadius), height: CGFloat(gridSize))
            verticalCylinder.radialSegmentCount = 12  // Higher resolution for anti-aliasing
            verticalCylinder.heightSegmentCount = 1   // Keep height simple
            verticalCylinder.materials = [material]
            
            let verticalNode = SCNNode(geometry: verticalCylinder)
            verticalNode.position = SCNVector3(x, 0, 0)
            // Cylinder is already vertical by default
            
            linesNode.addChildNode(verticalNode)
        }
        
        // Create horizontal lines centered around origin
        for i in startIndex...endIndex {
            let y = Float(i) * step
            
            // Calculate major line based on world position, not array index, to maintain pattern during wrapping
            let worldGridY = Int(round(y / step))
            let shouldDraw = isMajor ? (worldGridY % majorStep == 0) : (worldGridY % majorStep != 0)
            guard shouldDraw else { continue }
            
            // Create horizontal cylinder line with higher resolution for smoother edges
            let horizontalCylinder = SCNCylinder(radius: CGFloat(cylinderRadius), height: CGFloat(gridSize))
            horizontalCylinder.radialSegmentCount = 12  // Higher resolution for anti-aliasing
            horizontalCylinder.heightSegmentCount = 1   // Keep height simple
            horizontalCylinder.materials = [material]
            
            let horizontalNode = SCNNode(geometry: horizontalCylinder)
            horizontalNode.position = SCNVector3(0, y, 0)
            // Rotate 90 degrees around Z axis to make it horizontal
            horizontalNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            
            linesNode.addChildNode(horizontalNode)
        }
        
        return linesNode
    }
}

#Preview {
    struct GridPreview: View {
        @State private var spacing: CGFloat = 16
        @State private var majorEvery: Int = 4
        @State private var lineWidth: CGFloat = 1
        @State private var majorLineWidth: CGFloat = 1.0
        @State private var colorOpacity: Double = 1
        @State private var majorColorOpacity: Double = 1
        @State private var velocityX: CGFloat = 0
        @State private var velocityY: CGFloat = 0
        @State private var allowsCameraControl: Bool = false
        @State private var gyroEnabled: Bool = false
        @State private var gyroSensitivityX: CGFloat = 50
        @State private var gyroSensitivityY: CGFloat = 50
        @State private var cameraRotationX: CGFloat = 0  // Pitch
        @State private var cameraRotationY: CGFloat = 0  // Yaw  
        @State private var cameraRotationZ: CGFloat = 0  // Roll
        
        var body: some View {
            VStack {
                ZStack {
                    // Test background to verify transparency
//                    LinearGradient(
//                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
                    
                    InfiniteGridView(
                        spacing: spacing,
                        majorEvery: majorEvery,
                        color: .white.opacity(colorOpacity),
                        majorColor: .red.opacity(majorColorOpacity),
                        lineWidth: lineWidth,
                        majorLineWidth: majorLineWidth,
                        velocityX: velocityX,
                        velocityY: velocityY,
                        allowsCameraControl: allowsCameraControl,
                        gyroSensitivityX: gyroEnabled ? gyroSensitivityX : nil,
                        gyroSensitivityY: gyroEnabled ? gyroSensitivityY : nil,
                        cameraRotationX: cameraRotationX != 0 ? cameraRotationX : nil,
                        cameraRotationY: cameraRotationY != 0 ? cameraRotationY : nil,
                        cameraRotationZ: cameraRotationZ != 0 ? cameraRotationZ : nil
                    )
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Spacing: \(Int(spacing))pt")
                        Slider(value: $spacing, in: 8...32, step: 1)
                    }
                    
                    HStack {
                        Text("Major Every: \(majorEvery)")
                        Slider(value: Binding(
                            get: { Double(majorEvery) },
                            set: { majorEvery = Int($0) }
                        ), in: 2...10, step: 1)
                    }
                    
                    HStack {
                        Text("Line Width: \(lineWidth, specifier: "%.1f")")
                        Slider(value: $lineWidth, in: 0.1...3.0, step: 0.1)
                    }
                    
                    HStack {
                        Text("Major Line Width: \(majorLineWidth, specifier: "%.1f")")
                        Slider(value: $majorLineWidth, in: 0.1...5.0, step: 0.1)
                    }
                    
                    HStack {
                        Text("Color Opacity: \(colorOpacity, specifier: "%.2f")")
                        Slider(value: $colorOpacity, in: 0.0...1.0, step: 0.01)
                    }
                    
                    HStack {
                        Text("Major Color Opacity: \(majorColorOpacity, specifier: "%.2f")")
                        Slider(value: $majorColorOpacity, in: 0.0...1.0, step: 0.01)
                    }
                    
                    HStack {
                        Text("Velocity X: \(Int(velocityX))pt/s")
                        Slider(value: $velocityX, in: -100...100, step: 5)
                    }
                    
                    HStack {
                        Text("Velocity Y: \(Int(velocityY))pt/s")
                        Slider(value: $velocityY, in: -100...100, step: 5)
                    }
                    
                    HStack {
                        Text("Camera Control")
                        Spacer()
                        Toggle("", isOn: $allowsCameraControl)
                    }
                    
                    HStack {
                        Text("Gyro Enabled")
                        Spacer()
                        Toggle("", isOn: $gyroEnabled)
                    }
                    
                    if gyroEnabled {
                        HStack {
                            Text("Gyro X Sensitivity: \(Int(gyroSensitivityX))")
                            Slider(value: $gyroSensitivityX, in: 0...200, step: 5)
                        }
                        
                        HStack {
                            Text("Gyro Y Sensitivity: \(Int(gyroSensitivityY))")
                            Slider(value: $gyroSensitivityY, in: 0...200, step: 5)
                        }
                    }
                    
                    // Manual Camera Rotation Controls
                    Group {
                        HStack {
                            Text("Camera Pitch (X): \(Int(cameraRotationX))°")
                            Slider(value: $cameraRotationX, in: -90...90, step: 1)
                        }
                        
                        HStack {
                            Text("Camera Yaw (Y): \(Int(cameraRotationY))°")
                            Slider(value: $cameraRotationY, in: -180...180, step: 1)
                        }
                        
                        HStack {
                            Text("Camera Roll (Z): \(Int(cameraRotationZ))°")
                            Slider(value: $cameraRotationZ, in: -180...180, step: 1)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
    
    return GridPreview()
}

// MARK: - Equatable Implementation
extension InfiniteGridView {
    static func == (lhs: InfiniteGridView, rhs: InfiniteGridView) -> Bool {
        // Compare all parameters that affect the grid rendering
        return lhs.spacing == rhs.spacing &&
               lhs.majorEvery == rhs.majorEvery &&
               lhs.color == rhs.color &&
               lhs.majorColor == rhs.majorColor &&
               lhs.lineWidth == rhs.lineWidth &&
               lhs.majorLineWidth == rhs.majorLineWidth &&
               lhs.velocityX == rhs.velocityX &&
               lhs.velocityY == rhs.velocityY &&
               lhs.allowsCameraControl == rhs.allowsCameraControl &&
               lhs.gyroSensitivityX == rhs.gyroSensitivityX &&
               lhs.gyroSensitivityY == rhs.gyroSensitivityY &&
               lhs.cameraRotationX == rhs.cameraRotationX &&
               lhs.cameraRotationY == rhs.cameraRotationY &&
               lhs.cameraRotationZ == rhs.cameraRotationZ &&
               lhs.manualRotationAnimationDuration == rhs.manualRotationAnimationDuration &&
               lhs.animateSpacingChanges == rhs.animateSpacingChanges
    }
}
