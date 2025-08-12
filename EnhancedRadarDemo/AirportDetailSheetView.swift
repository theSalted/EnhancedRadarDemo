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
    
    var body: some View {
        NavigationStack {
            ZStack {
                #if DEBUG && targetEnvironment(simulator) && canImport(SwiftUI)
                simulatorStyleFix
                #endif
                
                
                ScrollView {
                    VStack {
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
                        .padding()
                        
                        
                        Spacer()
                    }
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
        }
    }
    
    #warning("DELETEME: Afer upgrade xcode version  ")
    var simulatorStyleFix: some View {
        Rectangle().foregroundStyle(.background)
            .ignoresSafeArea()
    }
}


#Preview {
    Text("Enhanced Radar")
        .sheet(isPresented: .constant(true)) {
        AirportDetailSheetView()
    }
}
