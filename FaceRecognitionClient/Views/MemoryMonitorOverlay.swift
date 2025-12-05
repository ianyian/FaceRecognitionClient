//
//  MemoryMonitorOverlay.swift
//  FaceRecognitionClient
//
//  Persistent memory monitoring overlay with stock-market style line chart
//  Created on December 4, 2025.
//  Updated December 5, 2025 - Fixed chart to show 5 minutes with scrolling animation
//

import SwiftUI
import Charts

// MARK: - Memory Monitor Overlay

struct MemoryMonitorOverlay: View {
    @EnvironmentObject private var memoryService: MemoryMonitorService
    @State private var isExpanded = true  // Start expanded to show chart
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Chart panel
                if isExpanded {
                    expandedView
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    compactView
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 120)  // Above tab bar / bottom area
        }
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    // MARK: - Compact View (Pill)
    
    private var compactView: some View {
        Button {
            isExpanded = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
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
            // Minimize button
            Button {
                isExpanded = false
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 10) {
                // Header with current value
                headerView
                
                // Stock-market style chart
                stockChartView
                    .frame(height: 100)
                
                // Time axis
                timeAxisView
            }
            .padding(12)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("App Memory")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let memory = memoryService.currentMemory {
                    Text(memory.appUsageFormatted)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(appUsageColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let memory = memoryService.currentMemory {
                    Text(memory.deviceFreeFormatted)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Stock Chart View (scrolls right to left like stock market)
    
    @ViewBuilder
    private var stockChartView: some View {
        if #available(iOS 16.0, *), !memoryService.memoryHistory.isEmpty {
            let history = memoryService.memoryHistory
            let maxValue = max((history.map(\.appUsedMB).max() ?? 100) * 1.1, 50)
            let minValue = max((history.map(\.appUsedMB).min() ?? 0) * 0.9, 0)
            
            Chart {
                ForEach(Array(history.enumerated()), id: \.element.id) { index, info in
                    // Use index for X axis to create scrolling effect
                    LineMark(
                        x: .value("Index", index),
                        y: .value("MB", info.appUsedMB)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("MB", info.appUsedMB)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartYScale(domain: minValue...maxValue)
            .chartXScale(domain: 0...300)  // Fixed 5-minute window (300 samples)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisValueLabel {
                        if let mb = value.as(Double.self) {
                            Text("\(Int(mb))")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
            .chartXAxis(.hidden)
            .animation(.linear(duration: 0.3), value: history.count)
        } else {
            // Fallback for iOS 15
            fallbackChartView
        }
    }
    
    // MARK: - Time Axis View
    
    private var timeAxisView: some View {
        HStack {
            Text("-5m")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text("-2.5m")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text("Now")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Fallback Chart (iOS 15)
    
    private var fallbackChartView: some View {
        GeometryReader { geometry in
            if !memoryService.memoryHistory.isEmpty {
                let maxValue = memoryService.memoryHistory.map(\.appUsedMB).max() ?? 100
                let minValue = max(0, (memoryService.memoryHistory.map(\.appUsedMB).min() ?? 0) - 10)
                let range = max(maxValue - minValue, 1)
                
                // Draw chart at fixed 300 width, scaling index position
                Path { path in
                    let points = memoryService.memoryHistory.enumerated().map { index, info -> CGPoint in
                        let x = CGFloat(index) / 300.0 * geometry.size.width  // Fixed 5-min scale
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
                .stroke(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
            }
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
            .environmentObject(MemoryMonitorService.shared)
    }
    .task {
        await MemoryMonitorService.shared.startMonitoring()
    }
}
