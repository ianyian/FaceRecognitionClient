# Student Management Feature - JavaScript Draft

## Overview

This is a JavaScript/HTML mockup for the Student Management feature designed for easy conversion to Swift/SwiftUI. The feature includes:

1. **Student List View** - Browse, search, and filter students
2. **Student Form View** - Register new students or edit existing ones
3. **Student Detail View** - View student profile and face samples
4. **Camera Integration** - Capture face samples with validation

## File Structure

```
mockup/student-management/
├── index.html      # View structure (maps to SwiftUI Views)
├── styles.css      # iOS-style design (maps to SwiftUI styling)
├── app.js          # Business logic (maps to ViewModels & Services)
└── README.md       # This file
```

## How to Test

1. Open `index.html` in a browser
2. The mock data includes 3 students
3. Test all features: list, search, filter, add, edit, delete

## Swift Conversion Guide

### JavaScript → Swift Mapping

| JavaScript Class        | Swift Equivalent                 | File                                                     |
| ----------------------- | -------------------------------- | -------------------------------------------------------- |
| `Student`               | `Student` struct                 | `Models/Student.swift` (exists)                          |
| `ViewState`             | `@ObservableObject` ViewModel    | `ViewModels/StudentViewModel.swift`                      |
| `MockFirebaseService`   | `FirebaseService`                | `Services/FirebaseService.swift` (exists)                |
| `CameraManager`         | `CameraService`                  | `Services/CameraService.swift` (exists)                  |
| `FaceValidationService` | `MediaPipeFaceLandmarkerService` | `Services/MediaPipeFaceLandmarkerService.swift` (exists) |
| `ToastService`          | SwiftUI Toast/Alert              | Built-in                                                 |

### Key SwiftUI Patterns

#### 1. Navigation Structure

```swift
// JavaScript: showView('list'), showView('form'), showView('detail')
// Swift equivalent:
NavigationStack {
    StudentListView()
        .navigationDestination(for: Student.self) { student in
            StudentDetailView(student: student)
        }
}
```

#### 2. State Management

```swift
// JavaScript: ViewState class with listeners
// Swift equivalent:
@MainActor
class StudentViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var searchTerm = ""
    @Published var statusFilter = "Registered"
    @Published var isLoading = false
    @Published var capturedImages: [UIImage] = []
}
```

#### 3. List with Search & Filter

```swift
// JavaScript: filterStudents() with search and status filter
// Swift equivalent:
List {
    ForEach(filteredStudents) { student in
        StudentRowView(student: student)
    }
}
.searchable(text: $searchTerm)

var filteredStudents: [Student] {
    students.filter { student in
        student.status == statusFilter &&
        (searchTerm.isEmpty || student.fullName.localizedCaseInsensitiveContains(searchTerm))
    }
}
```

#### 4. Form with Validation

```swift
// JavaScript: handleFormSubmit with validateForm()
// Swift equivalent:
Form {
    Section("Student Information") {
        TextField("First Name", text: $firstName)
        TextField("Last Name", text: $lastName)
        Picker("Class", selection: $className) {
            ForEach(classes) { cls in
                Text(cls.name).tag(cls.name)
            }
        }
    }

    Section("Parent Information") {
        TextField("Parent First Name", text: $parentFirstName)
        TextField("Parent Last Name", text: $parentLastName)
        TextField("WhatsApp Number", text: $parentPhone)
            .keyboardType(.phonePad)
    }
}
.onSubmit {
    Task { await submitForm() }
}
```

#### 5. Camera Integration

```swift
// JavaScript: CameraManager with startCamera(), capturePhoto()
// Swift: Use existing CameraService pattern
struct CameraSection: View {
    @StateObject private var cameraService = CameraService()
    @Binding var capturedImages: [UIImage]

    var body: some View {
        VStack {
            CameraPreviewView(previewLayer: cameraService.getPreviewLayer())

            Button("📷 Capture Face (\(capturedImages.count)/5)") {
                if let image = cameraService.capturePhoto() {
                    await validateAndAddFace(image)
                }
            }
            .disabled(!cameraService.isReady || capturedImages.count >= 5)
        }
    }
}
```

### New Swift Files to Create

1. **`Views/StudentListView.swift`**

   - Main list with search bar
   - Filter tabs (Registered/Deleted)
   - Navigation to detail/form views

2. **`Views/StudentFormView.swift`**

   - Registration/Edit form
   - Camera section for face capture
   - Form validation

3. **`Views/StudentDetailView.swift`**

   - Read-only student profile
   - Face samples gallery
   - Edit/Delete actions

4. **`Views/Components/StudentRowView.swift`**

   - Reusable list item component

5. **`ViewModels/StudentViewModel.swift`**
   - Shared state across views
   - Firebase operations
   - Form validation logic

### Firebase Service Extensions

Add these methods to existing `FirebaseService.swift`:

```swift
// MARK: - Student CRUD Operations

func createStudent(schoolId: String, student: Student) async throws -> String {
    // Create student document and return ID
}

func updateStudent(schoolId: String, studentId: String, data: [String: Any]) async throws {
    // Update student document
}

func deleteStudent(schoolId: String, studentId: String) async throws {
    // Soft delete (set status to "Deleted")
}

// MARK: - Classes

func loadClasses(schoolId: String) async throws -> [ClassInfo] {
    // Load available classes
}

// MARK: - Face Samples

func loadFaceSamples(schoolId: String, studentId: String) async throws -> [String] {
    // Load face sample data URLs
}

func saveFaceSamples(schoolId: String, studentId: String, samples: [UIImage]) async throws {
    // Save face samples to subcollection
}
```

## Design Decisions

1. **iOS Native Look** - CSS uses SF Pro font, system colors, and iOS spacing
2. **Dark Mode Support** - CSS variables adapt to `prefers-color-scheme`
3. **Safe Area** - Proper padding for notched iPhones
4. **Modals** - Similar to SwiftUI `.sheet()` and `.alert()`

## Next Steps

1. Review and test the JavaScript mockup
2. Confirm the UI/UX flow is correct
3. Proceed with Swift conversion
4. Integrate with existing CameraView for face scanning

## Questions?

Let me know if you need any modifications to the design or functionality before Swift conversion!
