//
//  ContentView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "airplane")
            Text("Enhanced Radar")
        }
        .sheet(isPresented: .constant(true)) {
            EventDetailSheetView()
        }
    }
}


#Preview {
    ContentView()
}
