import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var user: User?
    @Published var staff: Staff?
    @Published var currentSchool: School?  // Add currentSchool
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false  // Start false for immediate UI

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var staffListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    private let firebaseService = FirebaseService.shared  // Add FirebaseService dependency

    private init() {
        print("AuthService initialized. Setting up auth listener.")
        setupAuthListener()
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            print("Auth listener removed.")
        }
        staffListener?.remove()
        print("Staff listener removed.")
    }

    func setupAuthListener() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }

            print("Auth state changed. User: \(user?.uid ?? "nil")")
            self.user = user
            self.isLoggedIn = user != nil

            if let user = user {
                self.loadStaffProfile(for: user.uid)
            } else {
                self.staff = nil
            }
        }
    }

    func loadStaffProfile(for uid: String) {
        staffListener?.remove()  // Remove previous listener if any

        print("Loading staff profile for user: \(uid)")
        staffListener = Firestore.firestore().collection("staff").document(uid)
            .addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching staff profile: \(error.localizedDescription)")
                    self.staff = nil
                    return
                }

                guard let document = documentSnapshot, document.exists else {
                    print("Staff profile document not found for user: \(uid)")
                    self.staff = nil
                    return
                }

                do {
                    // Parse Staff from Firestore document using custom initializer
                    let decodedStaff = try Staff(from: document)
                    self.staff = decodedStaff
                    print(
                        "✅ Staff profile loaded: \(decodedStaff.email), Role: \(decodedStaff.role), School: \(decodedStaff.schoolId)"
                    )

                    // Load the school data for the staff's assigned school
                    Task { @MainActor in
                        do {
                            self.currentSchool = try await self.firebaseService.loadSchool(
                                schoolId: decodedStaff.schoolId)
                            print(
                                "✅ Staff's school (\(decodedStaff.schoolId)) loaded: \(self.currentSchool?.name ?? "unknown")"
                            )
                        } catch {
                            print(
                                "⚠️ Failed to load staff's school \(decodedStaff.schoolId): \(error.localizedDescription)"
                            )
                            self.currentSchool = nil
                        }
                    }

                } catch {
                    print("❌ Error parsing staff profile: \(error.localizedDescription)")
                    self.staff = nil
                }
            }
    }

    func signIn(email: String, password: String, schoolId: String) async throws -> Staff {
        let firebaseUser = try await Auth.auth().signIn(withEmail: email, password: password).user

        // Load staff profile to get roles and assigned school
        let staff = try await firebaseService.loadStaffProfile(uid: firebaseUser.uid)

        // Validate school access:
        // - Global users can access any school
        // - Non-global users must match their assigned school
        if !staff.isGlobalUser && staff.schoolId != schoolId {
            // Sign out if school doesn't match
            try Auth.auth().signOut()
            throw NSError(
                domain: "AuthService", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "You don't have access to this school. Please select '\(staff.schoolId)' or contact an administrator."
                ])
        }

        // If validation passes, set the staff and load the selected school
        self.user = firebaseUser
        self.staff = staff
        self.isLoggedIn = true

        // Load the actual school object for the selected schoolId (from LoginView)
        do {
            self.currentSchool = try await firebaseService.loadSchool(schoolId: schoolId)
        } catch {
            print("⚠️ Failed to load selected school \(schoolId): \(error.localizedDescription)")
            self.currentSchool = nil  // Set to nil if loading fails
        }

        // Update last login time
        try await firebaseService.updateLastLogin(staffId: staff.id)

        print(
            "✅ AuthService Sign-in successful for \(staff.email) at \(self.currentSchool?.name ?? "unknown")"
        )
        return staff
    }

    @MainActor
    func signOut() async {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.staff = nil
            self.isLoggedIn = false
            print("User signed out.")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}
