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
                #if DEBUG && targetEnvironment(simulator) && canImport(SwiftUI)
                simulatorStyleFix
                #endif
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "sun.rain.fill")
                                .symbolRenderingMode(.multicolor)
                                .resizable()
                                .scaledToFit()
                            VStack(alignment: .leading){
                                Text("Airport Weather")
                                    .font(.system(size: 18, weight: .medium))
                                Text("84° and scattered clouds")
                                    .font(.caption)
                                    .foregroundStyle(.primary.secondary)
                            }
                            
                            Spacer()
                            
                        }
                        .frame(height: 40)
                        .padding()
                        .background {
                            // TODO: Try use liquid glass
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lineWidth: 1)
                                .foregroundStyle(.foreground.tertiary)
                            
                        }
                        
                        
                        
                        VStack(alignment: .leading) {
                            Text("Operations")
                                .font(.headline)
                                .bold()
                            OperationsChartView()
                        }
                        .frame(height: 140)
                        .padding()
                        .background {
                            // TODO: Try use liquid glass
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lineWidth: 1)
                                .foregroundStyle(.foreground.tertiary)
                            
                        }
                        .padding(.bottom)
                        
                        Text("Start Listening")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        RadioCardView("Tower", description: "Control takeoffs & landing on runways 10 & 28") {
                            showRadioView = true
                        }
                        
                        RadioCardView("Ground", description: "Control takeoffs & landing on runways 10 & 28") {
                            showRadioView = true
                        }
                        
                        RadioCardView("Ground 2", description: "Control takeoffs & landing on runways 10 & 28") {
                            showRadioView = true
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                
            }
            .navigationTitle("SFO")
            .navigationSubtitle("San Francisco Int'l")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
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
    
    #warning("DELETEME: Afer upgrade xcode version  ")
    var simulatorStyleFix: some View {
        Rectangle().foregroundStyle(.background)
            .ignoresSafeArea()
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
