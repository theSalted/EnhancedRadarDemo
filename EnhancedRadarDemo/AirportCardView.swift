//
//  AirportCardView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/11/25.
//

import SwiftUI

struct AirportCardView: View {
    // Parameters (eye icon stays fixed)
    let code: String
    let airportName: String
    let statusSymbol: String
    let statusText: String
    let weatherSymbol: String
    let weatherText: String
    let viewCount: String

    var body: some View {
        VStack {
            HStack {
                HStack(alignment: .lastTextBaseline) {
                    Text(code)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(airportName)
                        .foregroundStyle(.primary.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                    Text(viewCount)
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
                    Image(systemName: statusSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30, alignment: .center)

                    Text(statusText)
                        .foregroundStyle(.primary.secondary)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 30, alignment: .center)

                // Right column (weather)
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: weatherSymbol)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30, alignment: .center)

                    Text(weatherText)
                        .foregroundStyle(.primary.secondary)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(minHeight: 30, alignment: .center)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(.background.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AirportCardView(
            code: "SFO",
            airportName: "San Francisco Int'l",
            statusSymbol: "gauge.open.with.lines.needle.33percent",
            statusText: "Moderately busy",
            weatherSymbol: "sun.rain.fill",
            weatherText: "74° and scattered clouds",
            viewCount: "13.4k"
        )
        .padding()

        AirportCardView(
            code: "EWR",
            airportName: "Newark Liberty Int'l",
            statusSymbol: "gauge.open.with.lines.needle.33percent",
            statusText: "About as busy as it gets",
            weatherSymbol: "cloud.heavyrain.fill",
            weatherText: "84° and raining with gusty winds",
            viewCount: "13.4k"
        )
        .padding()
    }
}
