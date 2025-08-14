//
//  AirportDetailSheetView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI
import Charts

struct AirportDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State var showRadioView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ZStack {
                            InfiniteGridView(
                                spacing: 30,
                                majorEvery: 1,
                                color: .secondary.opacity(0.5),
                                majorColor: .secondary.opacity(0.25),
                                lineWidth: 0.2,
                                majorLineWidth: 0.1,
                                allowsCameraControl: false,
                                gyroSensitivityX: 15,
                            )
                            .mask {
                                GeometryReader { proxy in
                                    Rectangle().fill(
                                        .radialGradient(
                                            stops: [
                                                .init(color: .white, location: 0.0),
                                                .init(color: .white, location: 0.35),
                                                .init(color: .clear, location: 0.9)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: min(proxy.size.width, proxy.size.height) * 0.65
                                        )
                                    )
                                }
                            }
                            
                            Image("SFOTower")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .offset(x: 70, y: 25)
                            
                            Rectangle()
                                .foregroundStyle(
                                    Gradient(
                                        stops: [
                                            .init(color: .clear, location: 0.0),
//                                            .init(color: .clear, location: 0.4),
//                                            .init(color: Color(uiColor: UIColor.secondarySystemBackground).opacity(0.9), location: 0.7),
                                            .init(color: Color(uiColor: UIColor.secondarySystemBackground), location: 0.95)
                                        ]
                                    )
                                )
                        }
                        .frame(height: 250)
                        .mask {
                            Rectangle()
                        }
                        
                        Group {
                            HStack(spacing: 15) {
                                Image(systemName: "sun.rain.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .resizable()
                                    .scaledToFit()
                                VStack(alignment: .leading){
                                    Text("Airport Weather")
                                        .foregroundStyle(Color(uiColor: UIColor.label))
                                        .font(.system(size: 18, weight: .medium))
                                    Text("84° and scattered clouds")
                                        .font(.caption)
                                        .foregroundStyle(.primary.secondary)
                                }
                                
                                Spacer()
                                
                            }
                            .frame(height: 40)
                            .padding()
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                            
                            VStack(alignment: .leading) {
                                Text("Operations")
                                    .foregroundStyle(Color(uiColor: UIColor.label))
                                    .font(.headline)
                                    .bold()
                                OperationsChartView()
                            }
                            .frame(height: 140)
                            .padding()
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                            .padding(.bottom)
                            
                            Text("Start Listening")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            RadioCardView("Tower", description: "Control takeoffs & landing on runways 10 & 28") {
                                HapticService.shared.medium()
                                showRadioView = true
                            }
                            
                            RadioCardView("Ground", description: "Control takeoffs & landing on runways 10 & 28") {
                                HapticService.shared.medium()
                                showRadioView = true
                            }
                            
                            RadioCardView("Ground 2", description: "Control takeoffs & landing on runways 10 & 28") {
                                HapticService.shared.medium()
                                showRadioView = true
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
                .contentMargins(.bottom, 100)
                .ignoresSafeArea()
            }
            .navigationTitle("SFO")
            .navigationSubtitle("San Francisco Int'l")
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
            }
            .sheet(isPresented: $showRadioView) {
                RadioSheetView()
            }
        }
    }
}

struct RadioCardView: View {
    var name: String
    var description: String
    var action: () -> Void
    
    init(_ name: String, description: String, _ action: @escaping () -> Void = {}) {
        self.name = name
        self.description = description
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                    Text(description)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 80)
                
                Image(systemName: "speaker.wave.2.bubble.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
            }
            .padding(20)
            .padding(.horizontal, 5)
            .background {
                // TODO: Try use liquid glass
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.background.secondary)
                
            }
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    @Previewable var contentViewModel = ContentViewModel()
    Text("Enhanced Radar")
        .sheet(isPresented: .constant(true)) {
        AirportDetailSheetView()
                .environment(contentViewModel)
    }
}
