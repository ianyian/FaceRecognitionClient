//
//  MemoryMonitorService.swift
//  FaceRecognitionClient
//
//  Memory monitoring service for tracking app and device memory usage
//  Created on December 4, 2025.
//

import Foundation
import UIKit
import Combine

// MARK: - Memory Info

struct MemoryInfo: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let appUsedMB: Double      // Memory used by this app
    let deviceFreeMB: Double   // Free memory on device
    let deviceTotalMB: Double  // Total device memory
    
    var appUsageFormatted: String {
        return String(format: "%.1f MB", appUsedMB)
    }
    
    var deviceFreeFormatted: String {
        if deviceFreeMB >= 1024 {
            return String(format: "%.1f GB", deviceFreeMB / 1024)
        }
        return String(format: "%.0f MB", deviceFreeMB)
    }
    
    var deviceTotalFormatted: String {
        return String(format: "%.1f GB", deviceTotalMB / 1024)
    }
    
    var appUsagePercentOfDevice: Double {
        guard deviceTotalMB > 0 else { return 0 }
        return (appUsedMB / deviceTotalMB) * 100
    }
}

// MARK: - Memory Monitor Service

@MainActor
final class MemoryMonitorService: ObservableObject {
    static let shared = MemoryMonitorService()
    
    @Published var currentMemory: MemoryInfo?
    @Published var memoryHistory: [MemoryInfo] = []
    @Published var isMonitoring = false
    
    private var timer: Timer?
    private let maxHistoryCount = 300  // Keep last 300 samples (5 minutes at 1s interval)
    private let updateInterval: TimeInterval = 1.0
    
    private init() {}
    
    // MARK: - Start/Stop Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Immediately get first reading
        updateMemoryInfo()
        
        // Schedule timer for continuous updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryInfo()
            }
        }
        
        print("📊 Memory monitoring started")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        memoryHistory.removeAll()
        currentMemory = nil
        print("📊 Memory monitoring stopped")
    }
    
    // MARK: - Memory Reading
    
    private func updateMemoryInfo() {
        let appMemory = Self.getAppMemoryUsage()
        let (deviceFree, deviceTotal) = Self.getDeviceMemoryInfo()
        
        let info = MemoryInfo(
            timestamp: Date(),
            appUsedMB: appMemory,
            deviceFreeMB: deviceFree,
            deviceTotalMB: deviceTotal
        )
        
        currentMemory = info
        memoryHistory.append(info)
        
        // Keep history limited
        if memoryHistory.count > maxHistoryCount {
            memoryHistory.removeFirst()
        }
    }
    
    /// Get current app memory usage in MB
    nonisolated private static func getAppMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0
    }
    
    /// Get device memory info (free and total) in MB
    nonisolated private static func getDeviceMemoryInfo() -> (free: Double, total: Double) {
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
        
        // Get available memory using vm_statistics64
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let freeMemory = Double(vmStats.free_count + vmStats.inactive_count) * Double(pageSize) / 1024.0 / 1024.0
            return (freeMemory, totalMemory)
        }
        
        return (0, totalMemory)
    }
    
    // MARK: - One-time Memory Check
    
    /// Get current memory info without starting monitoring
    func getCurrentMemoryInfo() -> MemoryInfo {
        let appMemory = Self.getAppMemoryUsage()
        let (deviceFree, deviceTotal) = Self.getDeviceMemoryInfo()
        
        return MemoryInfo(
            timestamp: Date(),
            appUsedMB: appMemory,
            deviceFreeMB: deviceFree,
            deviceTotalMB: deviceTotal
        )
    }
}
