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
        NavigationStack {
            AirportsView()
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
