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
    var body: some View {
        TabView {
            NavigationStack {
                AirportsView()
            }
            .tabItem { Label("Airports", systemImage: "airplane.up.right.app.fill") }
            
            NavigationStack {
                EventsView()
            }
            .tabItem { Label("Trending", systemImage: "chart.line.uptrend.xyaxis") }
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
