//
//  MemoryMonitorOverlay.swift
//  FaceRecognitionClient
//
//  Persistent memory monitoring overlay with line chart
//  Created on December 4, 2025.
//

import SwiftUI
import Charts

// MARK: - Memory Monitor Overlay

struct MemoryMonitorOverlay: View {
    @ObservedObject var memoryService = MemoryMonitorService.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
            
            if isExpanded {
                expandedView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                compactView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.trailing, 8)
        .padding(.bottom, 100)  // Above tab bar area
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    // MARK: - Compact View (Pill)
    
    private var compactView: some View {
        Button {
            isExpanded = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "memorychip")
                    .font(.caption)
                
                if let memory = memoryService.currentMemory {
                    Text(memory.appUsageFormatted)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(appUsageColor.opacity(0.9))
            )
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded View (Chart)
    
    private var expandedView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Close button
            Button {
                isExpanded = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 12) {
                // Current stats
                currentStatsView
                
                // Memory chart
                memoryChart
                    .frame(height: 80)
                
                // Legend
                legendView
            }
            .padding(12)
            .frame(width: 220)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            )
        }
    }
    
    // MARK: - Current Stats
    
    private var currentStatsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let memory = memoryService.currentMemory {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("App:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(memory.appUsageFormatted)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Available:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(memory.deviceFreeFormatted)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Total:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(memory.deviceTotalFormatted)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Memory Chart
    
    @ViewBuilder
    private var memoryChart: some View {
        if #available(iOS 16.0, *), !memoryService.memoryHistory.isEmpty {
            Chart {
                ForEach(memoryService.memoryHistory) { info in
                    LineMark(
                        x: .value("Time", info.timestamp),
                        y: .value("MB", info.appUsedMB)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", info.timestamp),
                        y: .value("MB", info.appUsedMB)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let mb = value.as(Double.self) {
                            Text("\(Int(mb))")
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .chartXAxis(.hidden)
        } else {
            // Fallback for iOS 15
            fallbackChartView
        }
    }
    
    // MARK: - Fallback Chart (iOS 15)
    
    private var fallbackChartView: some View {
        GeometryReader { geometry in
            if !memoryService.memoryHistory.isEmpty {
                let maxValue = memoryService.memoryHistory.map(\.appUsedMB).max() ?? 100
                let minValue = max(0, (memoryService.memoryHistory.map(\.appUsedMB).min() ?? 0) - 10)
                let range = max(maxValue - minValue, 1)
                
                Path { path in
                    let points = memoryService.memoryHistory.enumerated().map { index, info -> CGPoint in
                        let x = CGFloat(index) / CGFloat(max(1, memoryService.memoryHistory.count - 1)) * geometry.size.width
                        let y = (1 - CGFloat((info.appUsedMB - minValue) / range)) * geometry.size.height
                        return CGPoint(x: x, y: y)
                    }
                    
                    if let first = points.first {
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.orange, lineWidth: 2)
            }
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack {
            Text("Last 60s")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text("📊 App Memory")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helpers
    
    private var appUsageColor: Color {
        guard let memory = memoryService.currentMemory else { return .orange }
        
        // Color based on app memory usage
        if memory.appUsedMB > 300 {
            return .red
        } else if memory.appUsedMB > 150 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        MemoryMonitorOverlay()
    }
}
