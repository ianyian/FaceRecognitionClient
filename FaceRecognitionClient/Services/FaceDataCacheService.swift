//
//  FaceDataCacheService.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//

import Foundation

class FaceDataCacheService {
    static let shared = FaceDataCacheService()
    
    private let fileManager = FileManager.default
    private let cacheFileName = "facedata-cache.json"
    
    private var cachedData: FaceDataCache?
    
    private init() {
        // Load cache on init
        loadCacheFromDisk()
    }
    
    // MARK: - Cache File Path
    
    private var cacheFileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
    
    // MARK: - Save Cache
    
    func saveCache(_ faceData: [FaceDataDocument], version: Int) throws {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = isoFormatter.string(from: Date())
        
        let cache = FaceDataCache(
            version: version,
            lastUpdated: now,
            downloadedAt: now,
            totalRecords: faceData.count,
            faceData: faceData
        )
        
        guard let fileURL = cacheFileURL else {
            throw CacheError.invalidPath
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(cache)
        
        try data.write(to: fileURL)
        
        // Update in-memory cache
        cachedData = cache
        
        let sizeKB = data.count / 1024
        print("✅ Face data cache saved: \(faceData.count) records, \(sizeKB) KB")
    }
    
    // MARK: - Load Cache
    
    func loadCache() -> FaceDataCache? {
        if cachedData == nil {
            loadCacheFromDisk()
        }
        return cachedData
    }
    
    private func loadCacheFromDisk() {
        guard let fileURL = cacheFileURL,
              fileManager.fileExists(atPath: fileURL.path) else {
            cachedData = nil
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            cachedData = try decoder.decode(FaceDataCache.self, from: data)
            print("✅ Face data cache loaded: \(cachedData?.totalRecords ?? 0) records")
        } catch {
            print("⚠️ Failed to load cache: \(error)")
            cachedData = nil
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache() throws {
        guard let fileURL = cacheFileURL else {
            throw CacheError.invalidPath
        }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        
        cachedData = nil
        print("🗑️ Face data cache cleared")
    }
    
    // MARK: - Get Cache Status
    
    func getCacheStatus() -> FaceDataCacheStatus {
        guard let cache = loadCache(),
              let fileURL = cacheFileURL,
              let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int else {
            return .empty
        }
        
        // Count unique students
        let uniqueStudents = Set(cache.faceData.map { $0.studentId })
        
        return FaceDataCacheStatus(
            hasCache: true,
            recordCount: cache.totalRecords,
            studentCount: uniqueStudents.count,
            lastUpdated: cache.downloadDate,
            fileSizeKB: fileSize / 1024,
            version: cache.version
        )
    }
    
    // MARK: - Get Face Data for Matching
    
    func getFaceDataForMatching() -> [FaceDataDocument] {
        guard let cache = loadCache() else {
            return []
        }
        
        // Filter to only valid encodings
        return cache.faceData.filter { $0.hasValidEncoding }
    }
    
    // MARK: - Reload from Disk
    
    func reloadFromDisk() {
        cachedData = nil
        loadCacheFromDisk()
    }
}

// MARK: - Cache Errors

enum CacheError: Error, LocalizedError {
    case invalidPath
    case saveFailed(String)
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "Invalid cache file path"
        case .saveFailed(let message):
            return "Failed to save cache: \(message)"
        case .loadFailed(let message):
            return "Failed to load cache: \(message)"
        }
    }
}
