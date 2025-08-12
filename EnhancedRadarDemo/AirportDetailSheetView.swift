//
//  AirportDetailSheetView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

struct AirportDetailSheetView: View {
    var body: some View {
        
    }
}


#Preview {
    Text("Enhanced Radar")
        .sheet(isPresented: .constant(true)) {
        AirportDetailSheetView()
    }
}
