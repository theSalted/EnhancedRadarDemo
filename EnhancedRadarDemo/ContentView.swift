//
//  ContentView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

@Observable
class ContentViewModel {
    var showRadioView = false
    var showAirportDetailView = false
}


struct ContentView: View {
    @State var showAirportDetailView = false
    
    @State private var scrollProperties: ScrollGeometry = .init(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(),
        containerSize: .zero
    )
    
    @State private var scrollPosition: ScrollPosition = .init()
    
    var body: some View {
        NavigationStack {
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
                            
                            Image("SFOTower")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 400)
                                .offset(x: 50, y: 30)
                                .mask {
                                    Rectangle()
                                }
                                .offset(x:15, y:10)
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
                                    RoundedRectangle(cornerRadius: 20 * scrollProperties.featureTriggerProgress)
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
                            
                            VStack {
                                Spacer(minLength: 300)
                                HStack {
                                    HStack(alignment: .lastTextBaseline) {
                                        Text("SFO")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Text("San Francisco Int’l")
                                            .foregroundStyle(.primary.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "eye.fill")
                                        Text("13.4k")
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.viewCounterForeground)
                                    .padding(5)
                                    .padding(.horizontal, 2)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6)
                                            .foregroundStyle(.viewCounterBackground)
                                    }
                                }
                                
                                // Business + Weather (fixed column widths)
                                HStack(spacing: 12) {
                                    // Left column (status)
                                    HStack(alignment: .center, spacing: 10) {
                                        Image(systemName: "gauge.open.with.lines.needle.33percent")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30, alignment: .center)

                                        Text("About as busy as it gets")
                                            .foregroundStyle(.primary.secondary)
                                            .font(.system(size: 13))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 30, alignment: .center)

                                    // Right column (weather)
                                    HStack(alignment: .center, spacing: 10) {
                                        Image(systemName: "cloud.heavyrain.fill")
                                            .symbolRenderingMode(.multicolor)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30, alignment: .center)

                                        Text("84° and raining with gusty winds")
                                            .foregroundStyle(.primary.secondary)
                                            .font(.system(size: 13))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .frame(minHeight: 30, alignment: .center)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 15 * scrollProperties.featureTriggerProgress)
                    .buttonStyle(.plain)
                    
                    Group {
                        AirportCardView(
                            code: "EWR",
                            airportName: "Newark Liberty Int'l",
                            statusSymbol: "gauge.open.with.lines.needle.33percent",
                            statusText: "Moderately busy",
                            weatherSymbol: "cloud.heavyrain.fill",
                            weatherText: "84° and raining with gusty winds",
                            viewCount: "13.4k"
                        ){
                            showAirportDetailView = true
                        }
                        
                        AirportCardView(
                            code: "MIA",
                            airportName: "Miami Int'l",
                            statusSymbol: "gauge.open.with.lines.needle.33percent",
                            statusText: "Moderately busy",
                            weatherSymbol: "cloud.heavyrain.fill",
                            weatherText: "84° and raining with gusty winds",
                            viewCount: "13.4k"
                        ){
                            showAirportDetailView = true
                        }
                        
                        AirportCardView(
                            code: "ATL",
                            airportName: "Atlanta Int'l",
                            statusSymbol: "gauge.open.with.lines.needle.33percent",
                            statusText: "Moderately busy",
                            weatherSymbol: "cloud.heavyrain.fill",
                            weatherText: "84° and raining with gusty winds",
                            viewCount: "13.4k"
                        ) {
                            showAirportDetailView = true
                        }
                        
                        AirportCardView(
                            code: "EWR",
                            airportName: "Newark Liberty Int'l",
                            statusSymbol: "gauge.open.with.lines.needle.33percent",
                            statusText: "Moderately busy",
                            weatherSymbol: "cloud.heavyrain.fill",
                            weatherText: "84° and raining with gusty winds",
                            viewCount: "13.4k"
                        ) {
                            showAirportDetailView = true
                        }
                        
                        AirportCardView(
                            code: "MIA",
                            airportName: "Miami Int'l",
                            statusSymbol: "gauge.open.with.lines.needle.33percent",
                            statusText: "Moderately busy",
                            weatherSymbol: "cloud.heavyrain.fill",
                            weatherText: "84° and raining with gusty winds",
                            viewCount: "13.4k"
                        ) {
                            showAirportDetailView = true
                        }
                    }
                        .padding(.horizontal)
                }
            }
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }, action: { oldValue, newValue in
                scrollProperties = newValue
                
            })
            .ignoresSafeArea()
            .navigationTitle("Airports")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAirportDetailView) {
                AirportDetailSheetView()
            }
                    
        }
    }
}


extension ScrollGeometry {
    var offsetY: CGFloat {
        contentOffset.y + contentInsets.top
    }
    
    var featureTriggerProgress: CGFloat {
        min(offsetY / 200, 1)
    }
}

#Preview {
    ContentView()
}
