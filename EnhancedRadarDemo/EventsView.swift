//
//  EventsView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/12/25.
//

import SwiftUI

struct EventsView: View {
    @State var showAirportDetailView = false
    
    @State private var scrollProperties: ScrollGeometry = .init(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(),
        containerSize: .zero
    )
    
    @State private var scrollPosition: ScrollPosition = .init()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button {
                    showAirportDetailView = true
                } label: {
                    ZStack {
                        
                        BackgroundGridPattern(
                            spacing: 80,
                            majorEvery: 1
                        )
                        .opacity(1 - scrollProperties.featureTriggerProgress)
                        
                        Image("DeltaPlane")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 400)
                            .mask {
                                Rectangle()
                            }
                            .padding(.horizontal)
                            .opacity(1 - scrollProperties.featureTriggerProgress)
                        
                        Rectangle()
                            .glassEffect(.regular.interactive(), in: Rectangle())
                            .mask {
                                Rectangle()
                                    .foregroundStyle(
                                        Gradient(
                                            stops: [
                                                .init(color: .clear, location: 0.0),
                                                .init(color: .clear, location: 0.6),
                                                .init(color: .black, location: 0.8),
                                                .init(color: .black, location: 0.9)
                                            ]
                                        )
                                    )
                                    .opacity(1 - scrollProperties.featureTriggerProgress)
                            }
                            .scaleEffect(1.1)
                            .mask {
                                RoundedRectangle(cornerRadius: 16 * scrollProperties.featureTriggerProgress)
                            }
                            .opacity(1 * scrollProperties.featureTriggerProgress)
                        
                        RoundedRectangle(cornerRadius: 20 * scrollProperties.featureTriggerProgress)
                            .foregroundStyle(
                                Gradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .clear, location: 0.5),
                                        .init(color: Color(uiColor: UIColor.secondarySystemBackground), location: 1.0)
                                    ]
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Spacer(minLength: 300)
                            
                            Text("Small plane skids of runway and into Lake Washington")
                                .font(.title3)
                                .fontWeight(.medium)
                            HStack {
                                Text("LIVE")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6)
                                            .foregroundStyle(.red)
                                    }
                                    .padding(.trailing, 2)
                                Label("15.2k", systemImage: "eye.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Circle()
                                    .frame(width: 4)
                                    .foregroundStyle(.secondary)
                                Text("SFO")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Circle()
                                    .frame(width: 4)
                                    .foregroundStyle(.secondary)
                                Text("B737")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Image("planeSymbolName")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 22)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
                .padding(.horizontal, 15 * scrollProperties.featureTriggerProgress)
                .buttonStyle(.plain)
                
                Group {
                    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
                    
                    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
                    
                    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
                    
                    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
                    
                    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
                }
                    .padding(.horizontal)
            }
        }
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }, action: { oldValue, newValue in
            scrollProperties = newValue
            
        })
        .ignoresSafeArea()
        .navigationTitle("Trending")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAirportDetailView) {
            AirportDetailSheetView()
        }
    }
}

#Preview {
    NavigationStack {
        EventsView()
    }
}
