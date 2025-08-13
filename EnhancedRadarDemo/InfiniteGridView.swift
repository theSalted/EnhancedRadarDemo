//
//  InfiniteGridView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/13/25.
//

import SwiftUI
import SceneKit

struct InfiniteGridView: View {
    // Grid properties
    var spacing: CGFloat = 16
    var majorEvery: Int = 4
    var color: Color = .secondary.opacity(1)
    var majorColor: Color = .secondary.opacity(1)
    var lineWidth: CGFloat = 0.5
    var majorLineWidth: CGFloat = 1
    
    var body: some View {
        TransparentSceneView(scene: createGridScene())
            .ignoresSafeArea()
    }
    
    private func createGridScene() -> SCNScene {
        let scene = SCNScene()
        
        // Make scene background transparent
        scene.background.contents = UIColor.clear
        
        // Create grid geometry
        let gridNode = createGridNode()
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
        
        // Grid dimensions - make it large enough to feel infinite
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
        material.emission.contents = UIColor(lineColor)  // Make lines glow
        material.lightingModel = .constant  // Unlit material
        material.isDoubleSided = true
        material.transparency = 1.0
        geometry.materials = [material]
        
        linesNode.geometry = geometry
        return linesNode
    }
}

struct TransparentSceneView: UIViewRepresentable {
    let scene: SCNScene
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.clear
        scnView.isOpaque = false
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
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
                        majorLineWidth: majorLineWidth
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
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
    
    return GridPreview()
}
