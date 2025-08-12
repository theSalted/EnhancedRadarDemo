//
//  ContentView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    @State var showEventDetailView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<40) { i in
                        VStack {
                            HStack {
                                Text("SFO")
                                Text("San Francisco Int'l")
                                
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.large)
                    
        }
        .sheet(isPresented: $showEventDetailView) {
            EventDetailSheetView()
        }
    }
}


#Preview {
    ContentView()
}
