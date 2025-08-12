//
//  EventCardView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/12/25.
//

import SwiftUI

struct EventCardView: View {
    
    let action: () -> Void
    let text: String
    let time: String
    let airportCode: String
    let planeType: String
    let planeSymbolName: String
    
    init(
        _ text: String,
        time: String,
        airportCode: String,
        planeType: String,
        planeSymbolName: String,
        _ action: @escaping () -> Void = {}
    ) {
        self.text = text
        self.time = time
        self.airportCode = airportCode
        self.planeType = planeType
        self.planeSymbolName = planeSymbolName
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(.title3)
                    .fontWeight(.medium)
                HStack {
                    Text(time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Circle()
                        .frame(width: 4)
                        .foregroundStyle(.secondary)
                    Text(airportCode)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Circle()
                        .frame(width: 4)
                        .foregroundStyle(.secondary)
                    Text(planeType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(planeSymbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .padding(.leading, 4)
                    Spacer()
                }
            }
            .padding()
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.background.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EventCardView("Small plane skids of runway and into Lake Washington", time: "4m ago", airportCode: "SFO", planeType: "B737", planeSymbolName: "B737Symbol")
    .padding()
}
