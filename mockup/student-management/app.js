/**
 * ============================================
 * Student Management - iOS Style Draft
 * JavaScript Implementation for Swift Conversion
 * ============================================
 *
 * This JavaScript code is designed to be easily converted to Swift.
 * Each class/function maps to SwiftUI concepts:
 *
 * - StudentManagementApp → SwiftUI App with @StateObject
 * - StudentListView → SwiftUI View with List
 * - StudentFormView → SwiftUI Form
 * - FirebaseService → FirebaseService.swift (already exists)
 * - CameraManager → CameraService.swift (already exists)
 *
 * State management uses patterns similar to:
 * - @State, @Published, @ObservableObject
 */

// ============================================
// Configuration Constants
// Maps to Swift Constants or AppConfig
// ============================================
const CONFIG = {
  MAX_FACE_SAMPLES: 5,
  MIN_FACE_SAMPLES: 3,
  SCHOOL_ID: "main-tuition-center", // Will come from login context
  TOAST_DURATION: 3000,
};

// ============================================
// Student Model
// Maps to Student.swift (already exists)
// ============================================
class Student {
  constructor(data = {}) {
    this.id = data.id || "";
    this.firstName = data.firstName || "";
    this.lastName = data.lastName || "";
    this.className = data.class || data.className || "";
    this.parentFirstName = data.parentFirstName || "";
    this.parentLastName = data.parentLastName || "";
    this.parentPhone = data.parentPhone || "";
    this.status = data.status || "Registered";
    this.registrationDate = data.registrationDate || null;
    this.updatedAt = data.updatedAt || null;
    this.faceEncoding = data.faceEncoding || null;
    this.avatarUrl = data.avatarUrl || null;
  }

  get fullName() {
    return `${this.firstName} ${this.lastName}`;
  }

  get isActive() {
    return this.status === "Registered";
  }

  get hasFaceEncoding() {
    return this.faceEncoding && this.faceEncoding.length > 0;
  }

  // Convert to Firestore document format
  toFirestore() {
    return {
      id: this.id,
      firstName: this.firstName,
      lastName: this.lastName,
      class: this.className,
      parentFirstName: this.parentFirstName,
      parentLastName: this.parentLastName,
      parentPhone: this.parentPhone,
      status: this.status,
      registrationDate: this.registrationDate,
      updatedAt: new Date().toISOString(),
      faceEncoding: this.faceEncoding,
      avatarUrl: this.avatarUrl,
    };
  }
}

// ============================================
// Class Model (for dropdown)
// Maps to Class struct in definitions
// ============================================
class ClassInfo {
  constructor(data = {}) {
    this.id = data.id || "";
    this.name = data.name || "";
  }
}

// ============================================
// View State Management
// Maps to SwiftUI @State and @Published
// ============================================
class ViewState {
  constructor() {
    // Current view state
    this.currentView = "list"; // 'list', 'form', 'detail'
    this.isEditMode = false;
    this.selectedStudentId = null;

    // List view state
    this.students = [];
    this.filteredStudents = [];
    this.searchTerm = "";
    this.statusFilter = "Registered";
    this.isLoading = false;

    // Form state
    this.formData = this.getEmptyFormData();
    this.capturedImages = [];
    this.existingImages = [];
    this.isSubmitting = false;
    this.isCameraOn = false;

    // Classes
    this.classes = [];

    // Listeners
    this.listeners = [];
  }

  getEmptyFormData() {
    return {
      studentFirstName: "",
      studentLastName: "",
      className: "",
      parentFirstName: "",
      parentLastName: "",
      parentPhone: "",
    };
  }

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  notify() {
    this.listeners.forEach((listener) => listener(this));
  }

  setState(updates) {
    Object.assign(this, updates);
    this.notify();
  }
}

// ============================================
// Firebase Service (Mock)
// Maps to FirebaseService.swift (already exists)
// In real Swift, use existing FirebaseService
// ============================================
class MockFirebaseService {
  constructor() {
    // Mock data for testing
    this.students = [
      new Student({
        id: "student-1",
        firstName: "Alice",
        lastName: "Wong",
        class: "Class A",
        parentFirstName: "John",
        parentLastName: "Wong",
        parentPhone: "+60123456789",
        status: "Registered",
        registrationDate: "2025-12-01T10:00:00Z",
      }),
      new Student({
        id: "student-2",
        firstName: "Bob",
        lastName: "Tan",
        class: "Class B",
        parentFirstName: "Mary",
        parentLastName: "Tan",
        parentPhone: "+60198765432",
        status: "Registered",
        registrationDate: "2025-12-02T14:30:00Z",
      }),
      new Student({
        id: "student-3",
        firstName: "Charlie",
        lastName: "Lee",
        class: "Class A",
        parentFirstName: "David",
        parentLastName: "Lee",
        parentPhone: "+60112233445",
        status: "Deleted",
        registrationDate: "2025-11-15T09:00:00Z",
      }),
    ];

    this.classes = [
      new ClassInfo({ id: "class-1", name: "Class A" }),
      new ClassInfo({ id: "class-2", name: "Class B" }),
      new ClassInfo({ id: "class-3", name: "Class C" }),
    ];

    this.faceSamples = {
      "student-1": [
        "data:image/jpeg;base64,/9j/4AAQ...", // placeholder
      ],
    };
  }

  // Swift equivalent: func loadStudents(schoolId: String) async throws -> [Student]
  async loadStudents(schoolId) {
    // Simulate network delay
    await this.delay(500);
    return [...this.students];
  }

  // Swift equivalent: func loadClasses(schoolId: String) async throws -> [ClassInfo]
  async loadClasses(schoolId) {
    await this.delay(300);
    return [...this.classes];
  }

  // Swift equivalent: func loadStudent(schoolId: String, studentId: String) async throws -> Student
  async loadStudent(schoolId, studentId) {
    await this.delay(300);
    const student = this.students.find((s) => s.id === studentId);
    if (!student) {
      throw new Error("Student not found");
    }
    return student;
  }

  // Swift equivalent: func loadFaceSamples(schoolId: String, studentId: String) async throws -> [String]
  async loadFaceSamples(schoolId, studentId) {
    await this.delay(200);
    return this.faceSamples[studentId] || [];
  }

  // Swift equivalent: func createStudent(schoolId: String, student: Student) async throws -> String
  async createStudent(schoolId, studentData) {
    await this.delay(500);
    const newId = `student-${Date.now()}`;
    const newStudent = new Student({
      ...studentData,
      id: newId,
      registrationDate: new Date().toISOString(),
    });
    this.students.push(newStudent);
    return newId;
  }

  // Swift equivalent: func updateStudent(schoolId: String, studentId: String, data: [String: Any]) async throws
  async updateStudent(schoolId, studentId, updates) {
    await this.delay(500);
    const index = this.students.findIndex((s) => s.id === studentId);
    if (index === -1) {
      throw new Error("Student not found");
    }
    this.students[index] = new Student({
      ...this.students[index],
      ...updates,
    });
  }

  // Swift equivalent: func deleteStudent(schoolId: String, studentId: String) async throws
  async deleteStudent(schoolId, studentId) {
    await this.delay(300);
    const index = this.students.findIndex((s) => s.id === studentId);
    if (index === -1) {
      throw new Error("Student not found");
    }
    this.students[index].status = "Deleted";
  }

  // Swift equivalent: func saveFaceSamples(schoolId: String, studentId: String, samples: [String]) async throws
  async saveFaceSamples(schoolId, studentId, samples) {
    await this.delay(300);
    this.faceSamples[studentId] = samples;
  }

  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

// ============================================
// Camera Manager
// Maps to CameraService.swift (already exists)
// ============================================
class CameraManager {
  constructor() {
    this.stream = null;
    this.videoElement = null;
    this.canvasElement = null;
  }

  // Swift equivalent: func startCamera() async throws
  async startCamera(videoElement, canvasElement) {
    this.videoElement = videoElement;
    this.canvasElement = canvasElement;

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user" },
      });
      this.videoElement.srcObject = this.stream;
      await this.videoElement.play();
      return true;
    } catch (error) {
      console.error("Camera error:", error);
      throw new Error("Could not access camera. Please check permissions.");
    }
  }

  // Swift equivalent: func stopCamera()
  stopCamera() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop());
      this.stream = null;
    }
    if (this.videoElement) {
      this.videoElement.srcObject = null;
    }
  }

  // Swift equivalent: func capturePhoto() -> UIImage?
  capturePhoto() {
    if (!this.videoElement || !this.canvasElement) {
      return null;
    }

    const video = this.videoElement;
    const canvas = this.canvasElement;

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;

    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    // Add watermark (similar to web version)
    this.addWatermark(canvas, ctx);

    return canvas.toDataURL("image/jpeg", 0.8);
  }

  addWatermark(canvas, ctx) {
    const text = "© Tuition Center";
    ctx.font = "12px Arial";
    ctx.fillStyle = "rgba(255, 255, 255, 0.7)";
    ctx.textAlign = "right";
    ctx.fillText(text, canvas.width - 10, canvas.height - 10);
  }

  isActive() {
    return this.stream !== null;
  }
}

// ============================================
// Face Validation Service (Mock)
// Maps to MediaPipeFaceLandmarkerService.swift
// ============================================
class FaceValidationService {
  // Swift equivalent: func validateFace(image: UIImage) async throws -> FaceValidationResult
  async validateFace(imageDataUrl) {
    // Simulate face detection delay
    await new Promise((resolve) => setTimeout(resolve, 500));

    // In real implementation, use MediaPipe
    // For mock, randomly succeed/fail
    const success = Math.random() > 0.1;

    if (success) {
      return {
        isValid: true,
        encoding: `mock_encoding_${Date.now()}`,
      };
    } else {
      return {
        isValid: false,
        error: "No face detected. Please ensure good lighting.",
      };
    }
  }
}

// ============================================
// Toast Notification Service
// Maps to SwiftUI Toast/Alert system
// ============================================
class ToastService {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
  }

  show(type, title, message) {
    const toast = document.createElement("div");
    toast.className = `toast ${type}`;

    const icons = {
      success: "✅",
      error: "❌",
      warning: "⚠️",
    };

    toast.innerHTML = `
            <span class="toast-icon">${icons[type] || "ℹ️"}</span>
            <div class="toast-content">
                <div class="toast-title">${title}</div>
                <div class="toast-message">${message}</div>
            </div>
        `;

    this.container.appendChild(toast);

    setTimeout(() => {
      toast.style.animation = "slideUp 0.3s ease reverse";
      setTimeout(() => toast.remove(), 300);
    }, CONFIG.TOAST_DURATION);
  }

  success(title, message = "") {
    this.show("success", title, message);
  }

  error(title, message = "") {
    this.show("error", title, message);
  }

  warning(title, message = "") {
    this.show("warning", title, message);
  }
}

// ============================================
// Main Application Controller
// Maps to SwiftUI @main App and ContentView
// ============================================
class StudentManagementApp {
  constructor() {
    // Initialize services
    this.state = new ViewState();
    this.firebase = new MockFirebaseService();
    this.camera = new CameraManager();
    this.faceValidator = new FaceValidationService();
    this.toast = new ToastService("toastContainer");

    // Bind methods
    this.handleSearch = this.handleSearch.bind(this);
    this.handleFilterChange = this.handleFilterChange.bind(this);
    this.handleCapture = this.handleCapture.bind(this);
    this.handleFormSubmit = this.handleFormSubmit.bind(this);

    // Initialize
    this.initializeDOM();
    this.setupEventListeners();
    this.loadInitialData();
  }

  // ========================================
  // DOM References
  // In Swift, these would be @IBOutlet or SwiftUI bindings
  // ========================================
  initializeDOM() {
    // Views
    this.views = {
      list: document.getElementById("studentListView"),
      form: document.getElementById("studentFormView"),
      detail: document.getElementById("studentDetailView"),
    };

    // Header
    this.backBtn = document.getElementById("backBtn");
    this.pageTitle = document.getElementById("pageTitle");
    this.addStudentBtn = document.getElementById("addStudentBtn");

    // Search & Filter
    this.searchInput = document.getElementById("searchInput");
    this.filterTabs = document.querySelectorAll(".filter-tab");
    this.studentList = document.getElementById("studentList");

    // Form elements
    this.studentForm = document.getElementById("studentForm");
    this.classSelect = document.getElementById("className");
    this.submitBtn = document.getElementById("submitBtn");
    this.submitBtnText = document.getElementById("submitBtnText");
    this.submitSpinner = document.getElementById("submitSpinner");

    // Camera elements
    this.cameraPreview = document.getElementById("cameraPreview");
    this.captureCanvas = document.getElementById("captureCanvas");
    this.cameraOverlay = document.getElementById("cameraOverlay");
    this.startCameraBtn = document.getElementById("startCameraBtn");
    this.captureBtn = document.getElementById("captureBtn");
    this.captureCount = document.getElementById("captureCount");
    this.newSamplesGrid = document.getElementById("newSamplesGrid");
    this.existingSamplesGrid = document.getElementById("existingSamplesGrid");
    this.existingSamples = document.getElementById("existingSamples");
    this.newSamplesTitle = document.getElementById("newSamplesTitle");
    this.faceSamplesDesc = document.getElementById("faceSamplesDesc");

    // Detail elements
    this.detailElements = {
      firstName: document.getElementById("detailFirstName"),
      lastName: document.getElementById("detailLastName"),
      className: document.getElementById("detailClassName"),
      regDate: document.getElementById("detailRegDate"),
      status: document.getElementById("detailStatus"),
      faceSamples: document.getElementById("detailFaceSamples"),
    };
    this.editStudentBtn = document.getElementById("editStudentBtn");
    this.deleteStudentBtn = document.getElementById("deleteStudentBtn");

    // Modals
    this.deleteModal = document.getElementById("deleteModal");
    this.deleteModalText = document.getElementById("deleteModalText");
    this.cancelDeleteBtn = document.getElementById("cancelDeleteBtn");
    this.confirmDeleteBtn = document.getElementById("confirmDeleteBtn");
    this.imageModal = document.getElementById("imageModal");
    this.previewImage = document.getElementById("previewImage");
    this.closeImageModal = document.getElementById("closeImageModal");
  }

  // ========================================
  // Event Listeners Setup
  // In Swift, use @IBAction or SwiftUI button actions
  // ========================================
  setupEventListeners() {
    // Navigation
    this.backBtn.addEventListener("click", () => this.navigateBack());
    this.addStudentBtn.addEventListener("click", () =>
      this.showAddStudentForm()
    );

    // Search & Filter
    this.searchInput.addEventListener("input", this.handleSearch);
    this.filterTabs.forEach((tab) => {
      tab.addEventListener("click", () =>
        this.handleFilterChange(tab.dataset.status)
      );
    });

    // Camera
    this.startCameraBtn.addEventListener("click", () => this.startCamera());
    this.captureBtn.addEventListener("click", this.handleCapture);

    // Form
    this.studentForm.addEventListener("submit", this.handleFormSubmit);

    // Detail actions
    this.editStudentBtn.addEventListener("click", () =>
      this.editCurrentStudent()
    );
    this.deleteStudentBtn.addEventListener("click", () =>
      this.showDeleteConfirmation()
    );

    // Delete modal
    this.cancelDeleteBtn.addEventListener("click", () =>
      this.hideDeleteModal()
    );
    this.confirmDeleteBtn.addEventListener("click", () => this.confirmDelete());

    // Image modal
    this.closeImageModal.addEventListener("click", () => this.hideImageModal());
    this.imageModal.addEventListener("click", (e) => {
      if (e.target === this.imageModal) this.hideImageModal();
    });

    // Subscribe to state changes
    this.state.subscribe(() => this.render());
  }

  // ========================================
  // Data Loading
  // Swift: Task { await loadData() }
  // ========================================
  async loadInitialData() {
    this.state.setState({ isLoading: true });

    try {
      const [students, classes] = await Promise.all([
        this.firebase.loadStudents(CONFIG.SCHOOL_ID),
        this.firebase.loadClasses(CONFIG.SCHOOL_ID),
      ]);

      this.state.setState({
        students,
        classes,
        isLoading: false,
      });

      this.filterStudents();
      this.populateClassDropdown();
    } catch (error) {
      console.error("Failed to load data:", error);
      this.toast.error("Load Error", error.message);
      this.state.setState({ isLoading: false });
    }
  }

  // ========================================
  // Navigation
  // Swift: NavigationLink, NavigationView
  // ========================================
  showView(viewName) {
    Object.keys(this.views).forEach((key) => {
      this.views[key].classList.toggle("active", key === viewName);
    });
    this.state.setState({ currentView: viewName });
    this.updateHeader();
  }

  updateHeader() {
    const { currentView, isEditMode, selectedStudentId } = this.state;

    switch (currentView) {
      case "list":
        this.backBtn.style.display = "none";
        this.addStudentBtn.style.display = "block";
        this.pageTitle.textContent = "Students";
        break;
      case "form":
        this.backBtn.style.display = "block";
        this.addStudentBtn.style.display = "none";
        this.pageTitle.textContent = isEditMode
          ? "Edit Student"
          : "Register Student";
        break;
      case "detail":
        this.backBtn.style.display = "block";
        this.addStudentBtn.style.display = "none";
        this.pageTitle.textContent = "Student Profile";
        break;
    }
  }

  navigateBack() {
    this.stopCamera();

    if (this.state.currentView === "form" && this.state.isEditMode) {
      // Go back to detail view if editing
      this.showStudentDetail(this.state.selectedStudentId);
    } else {
      // Go back to list
      this.state.setState({
        capturedImages: [],
        existingImages: [],
        isEditMode: false,
        selectedStudentId: null,
      });
      this.showView("list");
    }
  }

  // ========================================
  // Student List View
  // Swift: List with ForEach
  // ========================================
  handleSearch(e) {
    this.state.setState({ searchTerm: e.target.value });
    this.filterStudents();
  }

  handleFilterChange(status) {
    this.state.setState({ statusFilter: status });

    // Update UI
    this.filterTabs.forEach((tab) => {
      tab.classList.toggle("active", tab.dataset.status === status);
    });

    this.filterStudents();
  }

  filterStudents() {
    const { students, searchTerm, statusFilter } = this.state;
    const lowercaseSearch = searchTerm.toLowerCase();

    const filtered = students
      .filter((student) => {
        // Status filter
        if (student.status !== statusFilter) return false;

        // Search filter
        if (lowercaseSearch) {
          const fullName = student.fullName.toLowerCase();
          if (!fullName.includes(lowercaseSearch)) return false;
        }

        return true;
      })
      .sort((a, b) => {
        // Sort by updatedAt or registrationDate
        const dateA = new Date(a.updatedAt || a.registrationDate || 0);
        const dateB = new Date(b.updatedAt || b.registrationDate || 0);
        return dateB - dateA;
      });

    this.state.setState({ filteredStudents: filtered });
    this.renderStudentList();
  }

  renderStudentList() {
    const { filteredStudents, isLoading } = this.state;

    if (isLoading) {
      this.studentList.innerHTML =
        '<div class="loading">Loading students...</div>';
      return;
    }

    if (filteredStudents.length === 0) {
      this.studentList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">🎓</div>
                    <p>No students found matching your criteria.</p>
                </div>
            `;
      return;
    }

    this.studentList.innerHTML = filteredStudents
      .map(
        (student) => `
            <div class="student-item" data-id="${student.id}">
                <img 
                    class="student-avatar" 
                    src="${
                      student.avatarUrl ||
                      `https://ui-avatars.com/api/?name=${encodeURIComponent(
                        student.fullName
                      )}&background=random`
                    }" 
                    alt="${student.fullName}"
                    onerror="this.src='https://ui-avatars.com/api/?name=${encodeURIComponent(
                      student.fullName
                    )}&background=random'"
                >
                <div class="student-info">
                    <div class="student-name">${student.fullName}</div>
                    <div class="student-class">${
                      student.className || "No class"
                    }</div>
                </div>
                <span class="student-status ${student.status.toLowerCase()}">${
          student.status
        }</span>
                <span class="student-chevron">›</span>
            </div>
        `
      )
      .join("");

    // Add click handlers
    this.studentList.querySelectorAll(".student-item").forEach((item) => {
      item.addEventListener("click", () => {
        this.showStudentDetail(item.dataset.id);
      });
    });
  }

  // ========================================
  // Student Detail View
  // Swift: NavigationLink destination view
  // ========================================
  async showStudentDetail(studentId) {
    this.state.setState({ selectedStudentId: studentId });

    try {
      const student = await this.firebase.loadStudent(
        CONFIG.SCHOOL_ID,
        studentId
      );
      const faceSamples = await this.firebase.loadFaceSamples(
        CONFIG.SCHOOL_ID,
        studentId
      );

      // Update detail elements
      this.detailElements.firstName.textContent = student.firstName;
      this.detailElements.lastName.textContent = student.lastName;
      this.detailElements.className.textContent = student.className || "-";
      this.detailElements.regDate.textContent = student.registrationDate
        ? new Date(student.registrationDate).toLocaleDateString()
        : "-";
      this.detailElements.status.textContent = student.status;

      // Render face samples
      if (faceSamples.length > 0) {
        this.detailElements.faceSamples.innerHTML = faceSamples
          .map(
            (src, index) => `
                    <div class="face-sample" data-src="${src}">
                        <img src="${src}" alt="Face sample ${index + 1}">
                    </div>
                `
          )
          .join("");

        // Add click handlers for preview
        this.detailElements.faceSamples
          .querySelectorAll(".face-sample")
          .forEach((sample) => {
            sample.addEventListener("click", () => {
              this.showImagePreview(sample.dataset.src);
            });
          });
      } else {
        this.detailElements.faceSamples.innerHTML =
          '<p class="no-samples">No face samples available.</p>';
      }

      // Show/hide delete button based on status
      this.deleteStudentBtn.style.display =
        student.status === "Deleted" ? "none" : "flex";

      this.showView("detail");
    } catch (error) {
      console.error("Failed to load student:", error);
      this.toast.error("Load Error", error.message);
    }
  }

  // ========================================
  // Student Form View (Add/Edit)
  // Swift: Form with TextField, Picker
  // ========================================
  showAddStudentForm() {
    this.state.setState({
      isEditMode: false,
      selectedStudentId: null,
      formData: this.state.getEmptyFormData(),
      capturedImages: [],
      existingImages: [],
    });

    this.resetForm();
    this.updateFormUI();
    this.showView("form");
  }

  async editCurrentStudent() {
    const studentId = this.state.selectedStudentId;

    try {
      const student = await this.firebase.loadStudent(
        CONFIG.SCHOOL_ID,
        studentId
      );
      const faceSamples = await this.firebase.loadFaceSamples(
        CONFIG.SCHOOL_ID,
        studentId
      );

      this.state.setState({
        isEditMode: true,
        formData: {
          studentFirstName: student.firstName,
          studentLastName: student.lastName,
          className: student.className,
          parentFirstName: student.parentFirstName,
          parentLastName: student.parentLastName,
          parentPhone: student.parentPhone,
        },
        capturedImages: [],
        existingImages: faceSamples,
      });

      this.populateForm();
      this.updateFormUI();
      this.showView("form");
    } catch (error) {
      console.error("Failed to load student for edit:", error);
      this.toast.error("Load Error", error.message);
    }
  }

  populateForm() {
    const { formData } = this.state;

    document.getElementById("studentFirstName").value =
      formData.studentFirstName;
    document.getElementById("studentLastName").value = formData.studentLastName;
    document.getElementById("className").value = formData.className;
    document.getElementById("parentFirstName").value = formData.parentFirstName;
    document.getElementById("parentLastName").value = formData.parentLastName;
    document.getElementById("parentPhone").value = formData.parentPhone;
  }

  resetForm() {
    this.studentForm.reset();
    this.clearFormErrors();
  }

  updateFormUI() {
    const { isEditMode, capturedImages, existingImages } = this.state;

    // Update submit button text
    this.submitBtnText.textContent = isEditMode
      ? "Update Student"
      : "Register Student";

    // Update face samples description
    this.faceSamplesDesc.textContent = isEditMode
      ? "Optionally, replace existing face photos by capturing new ones."
      : "Capture 3-5 clear face photos.";

    // Update capture count
    this.captureCount.textContent = capturedImages.length;

    // Update samples title for edit mode
    if (isEditMode && capturedImages.length > 0) {
      this.newSamplesTitle.textContent = "New Samples (will replace current)";
    } else {
      this.newSamplesTitle.textContent = "New Samples";
    }

    // Show/hide existing samples section
    if (
      isEditMode &&
      existingImages.length > 0 &&
      capturedImages.length === 0
    ) {
      this.existingSamples.style.display = "block";
      this.renderExistingSamples();
    } else {
      this.existingSamples.style.display = "none";
    }

    // Render new samples
    this.renderNewSamples();
  }

  renderExistingSamples() {
    const { existingImages } = this.state;

    this.existingSamplesGrid.innerHTML = existingImages
      .map(
        (src, index) => `
            <div class="face-sample" data-src="${src}">
                <img src="${src}" alt="Existing sample ${index + 1}">
            </div>
        `
      )
      .join("");

    // Add click handlers for preview
    this.existingSamplesGrid
      .querySelectorAll(".face-sample")
      .forEach((sample) => {
        sample.addEventListener("click", () => {
          this.showImagePreview(sample.dataset.src);
        });
      });
  }

  renderNewSamples() {
    const { capturedImages } = this.state;

    if (capturedImages.length === 0) {
      this.newSamplesGrid.innerHTML = "";
      return;
    }

    this.newSamplesGrid.innerHTML = capturedImages
      .map(
        (src, index) => `
            <div class="face-sample" data-index="${index}">
                <img src="${src}" alt="New sample ${index + 1}">
                <button class="remove-btn" type="button" data-index="${index}">×</button>
            </div>
        `
      )
      .join("");

    // Add click handlers
    this.newSamplesGrid.querySelectorAll(".face-sample").forEach((sample) => {
      sample.querySelector("img").addEventListener("click", () => {
        this.showImagePreview(this.state.capturedImages[sample.dataset.index]);
      });
    });

    this.newSamplesGrid.querySelectorAll(".remove-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.removeCapture(parseInt(btn.dataset.index));
      });
    });
  }

  removeCapture(index) {
    const capturedImages = [...this.state.capturedImages];
    capturedImages.splice(index, 1);
    this.state.setState({ capturedImages });
    this.updateFormUI();
  }

  populateClassDropdown() {
    const { classes } = this.state;

    this.classSelect.innerHTML = '<option value="">Select a class</option>';
    classes.forEach((cls) => {
      const option = document.createElement("option");
      option.value = cls.name;
      option.textContent = cls.name;
      this.classSelect.appendChild(option);
    });
  }

  // ========================================
  // Camera Functions
  // Swift: CameraService.swift integration
  // ========================================
  async startCamera() {
    try {
      await this.camera.startCamera(this.cameraPreview, this.captureCanvas);
      this.cameraOverlay.classList.add("hidden");
      this.captureBtn.disabled = false;
      this.state.setState({ isCameraOn: true });
      this.toast.success("Camera On", "Camera is ready for capture.");
    } catch (error) {
      console.error("Camera error:", error);
      this.toast.error("Camera Error", error.message);
    }
  }

  stopCamera() {
    this.camera.stopCamera();
    this.cameraOverlay.classList.remove("hidden");
    this.captureBtn.disabled = true;
    this.state.setState({ isCameraOn: false });
  }

  async handleCapture() {
    const { capturedImages } = this.state;

    if (capturedImages.length >= CONFIG.MAX_FACE_SAMPLES) {
      this.toast.warning(
        "Limit Reached",
        `Maximum ${CONFIG.MAX_FACE_SAMPLES} samples allowed.`
      );
      return;
    }

    // Capture photo
    const imageDataUrl = this.camera.capturePhoto();
    if (!imageDataUrl) {
      this.toast.error("Capture Failed", "Could not capture image.");
      return;
    }

    // Validate face
    this.captureBtn.disabled = true;
    this.captureBtn.textContent = "🔍 Validating...";

    try {
      const validation = await this.faceValidator.validateFace(imageDataUrl);

      if (!validation.isValid) {
        this.toast.error("Face Detection Failed", validation.error);
        return;
      }

      // Add to captured images
      this.state.setState({
        capturedImages: [...capturedImages, imageDataUrl],
      });
      this.updateFormUI();

      this.toast.success(
        `Face ${capturedImages.length + 1} Captured`,
        "High quality face detected."
      );
    } catch (error) {
      console.error("Validation error:", error);
      this.toast.error("Validation Error", error.message);
    } finally {
      this.captureBtn.disabled = false;
      this.captureCount.textContent = this.state.capturedImages.length;
      this.captureBtn.innerHTML = `📷 Capture Face (<span id="captureCount">${this.state.capturedImages.length}</span>/5)`;
    }
  }

  // ========================================
  // Form Submission
  // Swift: Form validation and Firebase save
  // ========================================
  async handleFormSubmit(e) {
    e.preventDefault();

    if (!this.validateForm()) {
      return;
    }

    const { isEditMode, selectedStudentId, capturedImages } = this.state;

    // Check face samples for new registration
    if (!isEditMode && capturedImages.length < CONFIG.MIN_FACE_SAMPLES) {
      this.toast.error(
        "Insufficient Face Samples",
        `Please capture at least ${CONFIG.MIN_FACE_SAMPLES} face samples.`
      );
      return;
    }

    // If editing and adding new images, require minimum
    if (
      isEditMode &&
      capturedImages.length > 0 &&
      capturedImages.length < CONFIG.MIN_FACE_SAMPLES
    ) {
      this.toast.error(
        "Insufficient Face Samples",
        `If replacing images, provide at least ${CONFIG.MIN_FACE_SAMPLES} new ones.`
      );
      return;
    }

    this.setSubmitting(true);

    try {
      const formData = this.getFormData();

      if (isEditMode) {
        // Update existing student
        await this.firebase.updateStudent(
          CONFIG.SCHOOL_ID,
          selectedStudentId,
          formData
        );

        // Update face samples if new ones captured
        if (capturedImages.length > 0) {
          await this.firebase.saveFaceSamples(
            CONFIG.SCHOOL_ID,
            selectedStudentId,
            capturedImages
          );
        }

        this.toast.success(
          "Update Successful!",
          `${formData.firstName} has been updated.`
        );
      } else {
        // Create new student
        const studentId = await this.firebase.createStudent(
          CONFIG.SCHOOL_ID,
          formData
        );

        // Save face samples
        await this.firebase.saveFaceSamples(
          CONFIG.SCHOOL_ID,
          studentId,
          capturedImages
        );

        this.toast.success(
          "Registration Successful!",
          `${formData.firstName} has been registered.`
        );
      }

      // Reset and go back to list
      this.stopCamera();
      await this.loadInitialData();
      this.showView("list");
    } catch (error) {
      console.error("Submission failed:", error);
      this.toast.error(
        isEditMode ? "Update Failed" : "Registration Failed",
        error.message
      );
    } finally {
      this.setSubmitting(false);
    }
  }

  getFormData() {
    return {
      firstName: document.getElementById("studentFirstName").value.trim(),
      lastName: document.getElementById("studentLastName").value.trim(),
      class: document.getElementById("className").value,
      parentFirstName: document.getElementById("parentFirstName").value.trim(),
      parentLastName: document.getElementById("parentLastName").value.trim(),
      parentPhone: document.getElementById("parentPhone").value.trim(),
    };
  }

  validateForm() {
    this.clearFormErrors();
    let isValid = true;

    const fields = [
      {
        id: "studentFirstName",
        errorId: "firstNameError",
        minLength: 2,
        label: "First name",
      },
      {
        id: "studentLastName",
        errorId: "lastNameError",
        minLength: 2,
        label: "Last name",
      },
      {
        id: "className",
        errorId: "classNameError",
        minLength: 1,
        label: "Class",
      },
      {
        id: "parentFirstName",
        errorId: "parentFirstNameError",
        minLength: 2,
        label: "Parent's first name",
      },
      {
        id: "parentLastName",
        errorId: "parentLastNameError",
        minLength: 2,
        label: "Parent's last name",
      },
      {
        id: "parentPhone",
        errorId: "parentPhoneError",
        minLength: 10,
        label: "Phone number",
      },
    ];

    fields.forEach((field) => {
      const input = document.getElementById(field.id);
      const error = document.getElementById(field.errorId);
      const value = input.value.trim();

      if (value.length < field.minLength) {
        error.textContent = `${field.label} must be at least ${field.minLength} characters.`;
        input.style.borderColor = "var(--color-danger)";
        isValid = false;
      }
    });

    return isValid;
  }

  clearFormErrors() {
    document.querySelectorAll(".error-message").forEach((el) => {
      el.textContent = "";
    });
    document
      .querySelectorAll(".form-group input, .form-group select")
      .forEach((el) => {
        el.style.borderColor = "transparent";
      });
  }

  setSubmitting(isSubmitting) {
    this.state.setState({ isSubmitting });
    this.submitBtn.disabled = isSubmitting;
    this.submitSpinner.style.display = isSubmitting ? "block" : "none";
    this.submitBtnText.style.display = isSubmitting ? "none" : "block";
  }

  // ========================================
  // Delete Functionality
  // Swift: .alert() with destructive action
  // ========================================
  showDeleteConfirmation() {
    const student = this.state.students.find(
      (s) => s.id === this.state.selectedStudentId
    );
    this.deleteModalText.textContent = `This will mark '${student?.fullName}' as deleted. This action can be undone by an administrator.`;
    this.deleteModal.style.display = "flex";
  }

  hideDeleteModal() {
    this.deleteModal.style.display = "none";
  }

  async confirmDelete() {
    const studentId = this.state.selectedStudentId;

    try {
      await this.firebase.deleteStudent(CONFIG.SCHOOL_ID, studentId);
      this.toast.success(
        "Student Deleted",
        'Status has been set to "Deleted".'
      );

      this.hideDeleteModal();
      await this.loadInitialData();
      this.showView("list");
    } catch (error) {
      console.error("Delete failed:", error);
      this.toast.error("Delete Failed", error.message);
    }
  }

  // ========================================
  // Image Preview Modal
  // Swift: Sheet or fullScreenCover
  // ========================================
  showImagePreview(src) {
    this.previewImage.src = src;
    this.imageModal.style.display = "flex";
  }

  hideImageModal() {
    this.imageModal.style.display = "none";
  }

  // ========================================
  // Render (State Observer)
  // Swift: SwiftUI automatic view updates
  // ========================================
  render() {
    // This is called whenever state changes
    // In SwiftUI, views automatically update when @Published properties change
  }
}

// ============================================
// Initialize Application
// Swift: @main App init
// ============================================
document.addEventListener("DOMContentLoaded", () => {
  window.app = new StudentManagementApp();
  console.log("📱 Student Management App initialized");
});
