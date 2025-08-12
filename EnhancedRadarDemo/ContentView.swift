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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AirportCardView(
                        code: "SFO",
                        airportName: "San Francisco Int’l",
                        statusSymbol: "gauge.open.with.lines.needle.33percent",
                        statusText: "About as busy as it gets",
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
                .padding(.top)
            }
            .navigationTitle("Airports")
            .navigationBarTitleDisplayMode(.large)
                    
        }
        .sheet(isPresented: $showAirportDetailView) {
            AirportDetailSheetView()
        }
    }
}


#Preview {
    ContentView()
}
