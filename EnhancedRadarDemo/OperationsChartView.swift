//
//  OperationsChartView.swift
//  EnhancedRadarDemo
//
//  Created by Yuhao Chen on 8/12/25.
//

import SwiftUI
import Charts

struct OperationDataPoint {
    var time: Date
    var count: Double
}

// MARK: - Hour → Date helper (keeps everything on the same "sheet"/day)
private let cal = Calendar.current
private let referenceDay = cal.startOfDay(for: Date()) // or inject a fixed date if needed

@inline(__always)
private func hour(_ h: Int, minute m: Int = 0) -> Date {
    cal.date(bySettingHour: h, minute: m, second: 0, of: referenceDay)!
}

// Original data, now built as Dates
let historicalData: [OperationDataPoint] = [
    (7, 0.5), (8, 0.5), (9, 2), (10, 4), (11, 6), (12, 7.5),
    (13, 8.7), (14, 3), (15, 5), (16, 2.4), (17, 1.1), (18, 0.5),
].map { OperationDataPoint(time: hour($0.0), count: $0.1) }

let currentData: [OperationDataPoint] = [
    (7, 0), (8, 0.3), (9, 1), (10, 3), (11, 5), (12, 6), (13, 6.5),
].map { OperationDataPoint(time: hour($0.0), count: $0.1) }

struct OperationsChartView: View {
    // Match the old 6.5...18.5 domain using :30 minutes
    private let xStart = hour(6, minute: 30)
    private let xEnd   = hour(18, minute: 30)

    var body: some View {
        ZStack {
            // Background (historical) bars
            Chart {
                ForEach(historicalData, id: \.time) { shape in
                    BarMark(
                        x: .value("time", shape.time),
                        y: .value("count", shape.count),
                        width: .fixed(28)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(.background.tertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisValueLabel("") // keep labels visually hidden like before
                }
            }
            .chartYAxis {
                AxisMarks { _ in AxisGridLine().foregroundStyle(.clear) }
            }
            .chartYAxis(.hidden)
            .chartXScale(domain: xStart...xEnd)
            .chartYScale(domain: 0...10)

            // Foreground (current) bars
            Chart {
                ForEach(currentData, id: \.time) { shape in
                    BarMark(
                        x: .value("time", shape.time),
                        y: .value("count", shape.count),
                        width: .fixed(28)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(.bannerIncidentBackground)
                }
            }
            .chartXAxis {
                AxisMarks { mark in
                    AxisGridLine().foregroundStyle(.clear)
                    if mark.index < 3 {
                        AxisValueLabel()
                    } else {
                        AxisValueLabel {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundStyle(.opacity(0.7))
                        }
                    }
                    
                }
            }
            .chartYAxis {
                AxisMarks { _ in AxisGridLine().foregroundStyle(.clear) }
            }
            .chartYAxis(.hidden)
            .chartXScale(domain: xStart...xEnd)
            .chartYScale(domain: 0...10)
        }
    }
}

#Preview {
    OperationsChartView()
        .frame(height: 150)
}
