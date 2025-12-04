//
//  StudentAvatarView.swift
//  FaceRecognitionClient
//
//  Student Avatar Component - Loads from faceSamples (same as CoMa web app)
//  Created on December 4, 2025.
//  Updated December 4, 2025 - Memory optimized with caching
//

import SwiftUI
import FirebaseFirestore

// MARK: - Avatar Cache (singleton to prevent memory bloat)

/// Global image cache with memory limits to prevent OOM crashes
actor AvatarImageCache {
    static let shared = AvatarImageCache()
    
    private var cache: [String: UIImage] = [:]
    private var accessOrder: [String] = []  // LRU tracking
    private let maxCacheSize = 30  // Maximum number of cached images
    
    private init() {}
    
    func getImage(for studentId: String) -> UIImage? {
        if let image = cache[studentId] {
            // Move to end (most recently used)
            accessOrder.removeAll { $0 == studentId }
            accessOrder.append(studentId)
            return image
        }
        return nil
    }
    
    func setImage(_ image: UIImage, for studentId: String) {
        // Evict oldest if at capacity
        while cache.count >= maxCacheSize, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
        
        cache[studentId] = image
        accessOrder.removeAll { $0 == studentId }
        accessOrder.append(studentId)
    }
    
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

// MARK: - Student Avatar View

/// Student Avatar that loads from faceSamples subcollection
/// Memory-optimized with LRU caching to prevent OOM crashes
struct StudentAvatarView: View {
    let studentId: String
    let studentName: String
    let schoolId: String
    let size: CGFloat
    
    @State private var avatarImage: UIImage?
    @State private var isLoading = true
    @State private var loadAttempted = false
    
    init(studentId: String, studentName: String, schoolId: String, size: CGFloat = 50) {
        self.studentId = studentId
        self.studentName = studentName
        self.schoolId = schoolId
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = avatarImage {
                // Cached or loaded image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if isLoading && !loadAttempted {
                // Initial loading state
                Circle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            } else {
                // Fallback - initials (no image found or error)
                Circle()
                    .fill(initialsBackgroundColor)
                    .overlay(
                        Text(initials)
                            .font(initialsFont)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .task(id: studentId) {
            await loadAvatar()
        }
    }
    
    // MARK: - Computed Properties
    
    private var initials: String {
        let components = studentName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(studentName.prefix(2)).uppercased()
    }
    
    private var initialsFont: Font {
        if size >= 50 {
            return .title2
        } else if size >= 40 {
            return .headline
        } else {
            return .caption
        }
    }
    
    private var initialsBackgroundColor: Color {
        // Generate consistent color based on student name
        let hash = studentName.hashValue
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .indigo, .teal, .cyan
        ]
        return colors[abs(hash) % colors.count]
    }
    
    // MARK: - Data Loading
    
    private func loadAvatar() async {
        // Check cache first
        if let cached = await AvatarImageCache.shared.getImage(for: studentId) {
            await MainActor.run {
                self.avatarImage = cached
                self.isLoading = false
                self.loadAttempted = true
            }
            return
        }
        
        // Load from Firestore
        do {
            let db = Firestore.firestore()
            let querySnapshot = try await db
                .collection("schools").document(schoolId)
                .collection("students").document(studentId)
                .collection("faceSamples")
                .limit(to: 1)
                .getDocuments()
            
            if let document = querySnapshot.documents.first,
               let dataUrl = document.data()["dataUrl"] as? String,
               !dataUrl.isEmpty,
               let image = createThumbnail(from: dataUrl) {
                // Cache the thumbnail (not the full image)
                await AvatarImageCache.shared.setImage(image, for: studentId)
                
                await MainActor.run {
                    self.avatarImage = image
                    self.isLoading = false
                    self.loadAttempted = true
                }
            } else {
                // No face sample found
                await MainActor.run {
                    self.avatarImage = nil
                    self.isLoading = false
                    self.loadAttempted = true
                }
            }
        } catch {
            print("⚠️ Avatar load failed for \(studentId): \(error.localizedDescription)")
            await MainActor.run {
                self.avatarImage = nil
                self.isLoading = false
                self.loadAttempted = true
            }
        }
    }
    
    /// Create a small thumbnail from base64 data URL to save memory
    private func createThumbnail(from dataUrl: String) -> UIImage? {
        // Extract base64 data
        let components = dataUrl.components(separatedBy: ",")
        guard components.count == 2,
              let imageData = Data(base64Encoded: components[1]),
              let originalImage = UIImage(data: imageData) else {
            return nil
        }
        
        // Create small thumbnail (60x60 is enough for avatars)
        let thumbnailSize = CGSize(width: 60, height: 60)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 1.0)
        originalImage.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StudentAvatarView(
            studentId: "test-123",
            studentName: "John Doe",
            schoolId: "main-tuition-center"
        )
        
        StudentAvatarView(
            studentId: "test-456",
            studentName: "Jane Smith",
            schoolId: "main-tuition-center",
            size: 80
        )
    }
    .padding()
}
