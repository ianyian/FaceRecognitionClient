//
//  WhatsAppNotificationService.swift
//  FaceRecognitionClient
//
//  Created on December 9, 2025.
//

import FirebaseFirestore
import Foundation

/// Service for sending WhatsApp notifications to parents via Firebase Cloud Function
class WhatsAppNotificationService {

    // Singleton instance
    static let shared = WhatsAppNotificationService()

    private let db = Firestore.firestore()

    private init() {}

    /// Send WhatsApp notification to parent when student is checked in
    /// - Parameters:
    ///   - studentId: The Firestore document ID of the matched student
    ///   - studentName: Name of the student (for the message)
    ///   - parentName: Name of the parent (for personalized greeting)
    ///   - parentPhone: Parent's WhatsApp phone number in international format
    ///   - schoolId: School ID for the attendance record
    ///   - timestamp: Time when face was detected (defaults to now)
    ///   - completion: Callback with success/failure result
    func sendAttendanceNotification(
        studentId: String,
        studentName: String,
        parentName: String?,
        parentPhone: String,
        schoolId: String,
        timestamp: Date = Date(),
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        print("📱 WhatsAppService: Preparing to send notification")
        print("   - Student: \(studentName) (\(studentId))")
        print("   - Parent: \(parentName ?? "N/A")")
        print("   - Phone: \(parentPhone)")
        print("   - School: \(schoolId)")

        // Format timestamp for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedTime = dateFormatter.string(from: timestamp)

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let checkInTime = timeFormatter.string(from: timestamp)

        // Create message text
        let greeting = parentName != nil ? "Hello \(parentName!)," : "Hello,"
        let messageBody = """
            \(greeting)

            ✅ Your child \(studentName) has checked in at \(checkInTime).

            Thank you!
            """

        // Create WhatsApp queue document
        // The backend Cloud Function will process this queue and send via Twilio
        let queueData: [String: Any] = [
            "to": parentPhone,  // Required by Cloud Function
            "body": messageBody,  // Required by Cloud Function
            "studentId": studentId,
            "studentName": studentName,
            "parentName": parentName ?? "Parent",
            "parentPhone": parentPhone,
            "schoolId": schoolId,
            "checkInTime": checkInTime,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending",
            "retryCount": 0,
            "messageType": "check_in",
        ]

        // Add to WhatsApp queue in Firestore
        // Path: /schools/{schoolId}/whatsapp-queue/{docId}
        let queueRef = db.collection("schools")
            .document(schoolId)
            .collection("whatsapp-queue")
            .document()

        queueRef.setData(queueData) { error in
            if let error = error {
                print(
                    "❌ WhatsAppService: Failed to create queue document: \(error.localizedDescription)"
                )
                completion(.failure(error))
                return
            }

            let queueId = queueRef.documentID
            print("✅ WhatsAppService: Queue document created: \(queueId)")
            print("   - Message will be processed by Cloud Function")
            print(
                "   - Parent will receive: 'Your child \(studentName) checked in at \(checkInTime)'"
            )

            completion(.success(queueId))
        }
    }

    /// Send WhatsApp notification with simple interface (fetches student details automatically)
    /// - Parameters:
    ///   - studentId: The student's document ID
    ///   - schoolId: The school ID
    ///   - timestamp: Check-in time
    ///   - completion: Result callback
    func sendNotificationForStudent(
        studentId: String,
        schoolId: String,
        timestamp: Date = Date(),
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        print("📱 WhatsAppService: Fetching student details for notification")

        // Fetch student document to get name and parent info
        db.collection("schools")
            .document(schoolId)
            .collection("students")
            .document(studentId)
            .getDocument { [weak self] snapshot, error in

                guard let self = self else { return }

                if let error = error {
                    print(
                        "❌ WhatsAppService: Failed to fetch student: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data(),
                    let firstName = data["firstName"] as? String,
                    let lastName = data["lastName"] as? String,
                    let parentPhone = data["parentPhone"] as? String,
                    !parentPhone.isEmpty
                else {

                    let error = NSError(
                        domain: "WhatsAppService",
                        code: 400,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Student document missing required fields (name or parentPhoneNumber)"
                        ]
                    )
                    print("❌ WhatsAppService: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                let studentName = "\(firstName) \(lastName)"
                let parentName = data["parentName"] as? String

                // Send notification with fetched details
                self.sendAttendanceNotification(
                    studentId: studentId,
                    studentName: studentName,
                    parentName: parentName,
                    parentPhone: parentPhone,
                    schoolId: schoolId,
                    timestamp: timestamp,
                    completion: completion
                )
            }
    }
}
