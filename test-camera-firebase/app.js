// Import Firebase SDK (using CDN version for simplicity)
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import {
  getFirestore,
  collection,
  addDoc,
  doc,
  getDoc,
  getDocs,
  deleteDoc,
  query,
  limit,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

// Firebase Configuration
// Automatically extracted from GoogleService-Info.plist
const firebaseConfig = {
  apiKey: "AIzaSyD1v8MYDb8HJ2fosj9H8eytWgmzWs-nwa8",
  authDomain: "studio-4796520355-68573.firebaseapp.com",
  projectId: "studio-4796520355-68573",
  storageBucket: "studio-4796520355-68573.appspot.com",
  messagingSenderId: "749344629546",
  appId: "1:749344629546:ios:703d99a87371cab385f453",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// DOM Elements
const loginSection = document.getElementById("loginSection");
const loginForm = document.getElementById("loginForm");
const emailInput = document.getElementById("emailInput");
const passwordInput = document.getElementById("passwordInput");
const loginBtn = document.getElementById("loginBtn");
const cameraSection = document.getElementById("cameraSection");
const videoElement = document.getElementById("videoElement");
const canvas = document.getElementById("canvas");
const captureBtn = document.getElementById("captureBtn");
const statusSection = document.getElementById("statusSection");
const statusIcon = document.getElementById("statusIcon");
const statusText = document.getElementById("statusText");
const statusDetails = document.getElementById("statusDetails");
const displaySection = document.getElementById("displaySection");
const displayImage = document.getElementById("displayImage");
const docId = document.getElementById("docId");
const docStaffId = document.getElementById("docStaffId");
const docTimestamp = document.getElementById("docTimestamp");
const downloadBtn = document.getElementById("downloadBtn");
const diagnosticSection = document.getElementById("diagnosticSection");
const testAuthBtn = document.getElementById("testAuthBtn");
const testFirestoreReadBtn = document.getElementById("testFirestoreReadBtn");
const testFirestoreWriteBtn = document.getElementById("testFirestoreWriteBtn");
const testSchoolsBtn = document.getElementById("testSchoolsBtn");
const diagnosticResults = document.getElementById("diagnosticResults");

let stream = null;
let capturedDocumentId = null;
let isAuthenticated = false;
let currentSchoolId = "main-tuition-center"; // Default school ID from key.md

// Initialize on page load
window.addEventListener("load", () => {
  updateStatus("⏳", "Ready", "Please login to continue", "ready");

  // Setup login form handler
  loginForm.addEventListener("submit", handleLogin);

  // Setup diagnostic button handlers
  testAuthBtn.addEventListener("click", runAuthTest);
  testFirestoreReadBtn.addEventListener("click", runFirestoreReadTest);
  testFirestoreWriteBtn.addEventListener("click", runFirestoreWriteTest);
  testSchoolsBtn.addEventListener("click", runSchoolsTest);
});

/**
 * Handle login form submission
 */
async function handleLogin(e) {
  e.preventDefault();

  const email = emailInput.value.trim();
  const password = passwordInput.value;

  if (!email || !password) {
    updateStatus("❌", "Error", "Please enter email and password", "error");
    return;
  }

  loginBtn.disabled = true;
  loginBtn.querySelector(".btn-text").textContent = "Signing in...";

  try {
    await authenticateUser(email, password);

    // Hide login section, show camera and diagnostic sections
    loginSection.style.display = "none";
    cameraSection.style.display = "block";
    captureBtn.style.display = "flex";
    diagnosticSection.style.display = "block";

    // Initialize camera
    await initCamera();
  } catch (error) {
    loginBtn.disabled = false;
    loginBtn.querySelector(".btn-text").textContent = "Sign In";
  }
}

/**
 * Authenticate user with Firebase
 */
async function authenticateUser(email, password) {
  try {
    updateStatus(
      "⏳",
      "Authenticating...",
      "Signing in to Firebase",
      "processing"
    );

    // Sign in with email and password
    const userCredential = await signInWithEmailAndPassword(
      auth,
      email,
      password
    );
    const user = userCredential.user;

    isAuthenticated = true;
    console.log("✅ Authenticated with Firebase:", user.email);
    console.log("User ID:", user.uid);

    updateStatus("✅", "Authenticated", `Signed in as ${email}`, "success");
  } catch (error) {
    console.error("Authentication error:", error);
    let errorMessage = error.message;

    // Provide helpful error messages
    if (error.code === "auth/invalid-credential") {
      errorMessage =
        "Invalid email or password. Please check your credentials.";
    } else if (error.code === "auth/user-not-found") {
      errorMessage =
        "No user found with this email. Please create an account in Firebase Console.";
    } else if (error.code === "auth/wrong-password") {
      errorMessage = "Incorrect password. Please try again.";
    }

    updateStatus("❌", "Authentication failed", errorMessage, "error");
    throw error;
  }
}

/**
 * Initialize camera stream
 */
async function initCamera() {
  try {
    if (!isAuthenticated) {
      updateStatus(
        "❌",
        "Not authenticated",
        "Please refresh the page",
        "error"
      );
      captureBtn.disabled = true;
      return;
    }

    updateStatus(
      "⏳",
      "Initializing camera...",
      "Requesting camera access",
      "processing"
    );

    stream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 1280 },
        height: { ideal: 720 },
        facingMode: "user", // front camera
      },
      audio: false,
    });

    videoElement.srcObject = stream;

    updateStatus(
      "✅",
      "Camera ready",
      'Click "Capture" to take a photo',
      "ready"
    );
    captureBtn.disabled = false;
  } catch (error) {
    console.error("Camera initialization error:", error);
    updateStatus(
      "❌",
      "Camera error",
      `Failed to access camera: ${error.message}`,
      "error"
    );
    captureBtn.disabled = true;
  }
}

/**
 * Capture photo from video stream
 */
function capturePhoto() {
  const context = canvas.getContext("2d");

  // Set canvas size to match video
  canvas.width = videoElement.videoWidth;
  canvas.height = videoElement.videoHeight;

  // Draw current video frame to canvas
  context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);

  // Convert canvas to base64 image (JPEG, 80% quality - same as iOS app)
  return canvas.toDataURL("image/jpeg", 0.8);
}

/**
 * Save image to Firestore
 */
async function saveToFirestore(imageDataUri) {
  // Get current user for staffId
  const currentUser = auth.currentUser;

  if (!currentUser) {
    throw new Error("No authenticated user found");
  }

  console.log(
    "🔐 Saving with user:",
    currentUser.email,
    "UID:",
    currentUser.uid
  );

  const loginPicturesRef = collection(
    db,
    "schools",
    currentSchoolId,
    "login-pictures"
  );

  const documentData = {
    staffId: currentUser.uid,
    staffEmail: currentUser.email,
    schoolId: currentSchoolId,
    timestamp: serverTimestamp(),
    imageData: imageDataUri,
  };

  console.log("📝 Document data:", {
    path: `/schools/${currentSchoolId}/login-pictures`,
    staffId: documentData.staffId,
    staffEmail: documentData.staffEmail,
    schoolId: documentData.schoolId,
    imageDataLength: imageDataUri.length,
  });

  try {
    const docRef = await addDoc(loginPicturesRef, documentData);
    console.log("✅ Document created with ID:", docRef.id);
    return docRef.id;
  } catch (error) {
    console.error("❌ Firestore write error:", error.code, error.message);
    throw error;
  }
}

/**
 * Load image from Firestore
 */
async function loadFromFirestore(documentId) {
  const docRef = doc(
    db,
    "schools",
    currentSchoolId,
    "login-pictures",
    documentId
  );
  const docSnap = await getDoc(docRef);

  if (docSnap.exists()) {
    return docSnap.data();
  } else {
    throw new Error("Document not found");
  }
}

/**
 * Handle capture button click
 */
captureBtn.addEventListener("click", async () => {
  try {
    if (!isAuthenticated) {
      updateStatus(
        "❌",
        "Not authenticated",
        "Please refresh the page",
        "error"
      );
      return;
    }

    // Disable button during processing
    captureBtn.disabled = true;
    updateStatus(
      "⏳",
      "Processing...",
      "Capturing image from camera",
      "processing"
    );

    // Step 1: Capture photo
    const imageDataUri = capturePhoto();
    console.log("📸 Image captured, size:", imageDataUri.length, "characters");

    updateStatus("⏳", "Processing...", "Saving to Firestore...", "processing");

    // Step 2: Save to Firestore
    const documentId = await saveToFirestore(imageDataUri);
    capturedDocumentId = documentId;
    console.log("✅ Saved to Firestore with ID:", documentId);

    updateStatus(
      "⏳",
      "Processing...",
      "Retrieving from Firestore...",
      "processing"
    );

    // Step 3: Retrieve from Firestore to verify
    const retrievedData = await loadFromFirestore(documentId);
    console.log("📥 Retrieved from Firestore");

    // Step 4: Display the retrieved image
    displayRetrievedImage(documentId, retrievedData);

    updateStatus(
      "✅",
      "Success!",
      "Image captured, saved, and retrieved successfully",
      "success"
    );

    // Re-enable button after 2 seconds
    setTimeout(() => {
      captureBtn.disabled = false;
      updateStatus(
        "✅",
        "Camera ready",
        'Click "Capture" to take another photo',
        "ready"
      );
    }, 2000);
  } catch (error) {
    console.error("Capture error:", error);
    updateStatus("❌", "Error", `Failed: ${error.message}`, "error");
    captureBtn.disabled = false;
  }
});

/**
 * Display retrieved image in the UI
 */
function displayRetrievedImage(documentId, data) {
  // Show display section
  displaySection.style.display = "block";
  displaySection.classList.add("fade-in");

  // Set image
  displayImage.src = data.imageData;

  // Set metadata
  docId.textContent = documentId;
  docStaffId.textContent = data.staffId;

  // Format timestamp
  if (data.timestamp) {
    const date = data.timestamp.toDate ? data.timestamp.toDate() : new Date();
    docTimestamp.textContent = date.toLocaleString();
  } else {
    docTimestamp.textContent = "Just now";
  }

  // Scroll to display section
  displaySection.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

/**
 * Handle download button click
 */
downloadBtn.addEventListener("click", () => {
  if (!displayImage.src) return;

  // Create a temporary link to trigger download
  const link = document.createElement("a");
  link.href = displayImage.src;
  link.download = `captured-image-${capturedDocumentId}.jpg`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  console.log("📥 Image downloaded");
});

/**
 * Update status display
 */
function updateStatus(icon, text, details, statusClass) {
  statusIcon.textContent = icon;
  statusText.textContent = text;
  statusDetails.textContent = details;

  // Remove all status classes
  statusSection.classList.remove(
    "status-ready",
    "status-processing",
    "status-success",
    "status-error"
  );

  // Add appropriate status class
  if (statusClass) {
    statusSection.classList.add(`status-${statusClass}`);
  }

  // Add processing animation
  if (statusClass === "processing") {
    statusIcon.classList.add("processing");
  } else {
    statusIcon.classList.remove("processing");
  }
}

/**
 * Diagnostic Test Functions
 */
function appendDiagnosticResult(message, isSuccess = true) {
  const color = isSuccess ? "#4CAF50" : "#f44336";
  const icon = isSuccess ? "✅" : "❌";
  diagnosticResults.innerHTML += `<div style="color: ${color};">${icon} ${message}</div>`;
  diagnosticResults.scrollTop = diagnosticResults.scrollHeight;
}

async function runAuthTest() {
  diagnosticResults.innerHTML =
    '<div style="color: #2196F3;">🔐 Testing Authentication...</div>';

  try {
    const user = auth.currentUser;
    if (user) {
      appendDiagnosticResult(`Auth Status: Signed in`, true);
      appendDiagnosticResult(`User Email: ${user.email}`, true);
      appendDiagnosticResult(`User UID: ${user.uid}`, true);
      appendDiagnosticResult(`Email Verified: ${user.emailVerified}`, true);
    } else {
      appendDiagnosticResult("Auth Status: Not signed in", false);
    }
  } catch (error) {
    appendDiagnosticResult(`Auth Test Failed: ${error.message}`, false);
  }
}

async function runFirestoreReadTest() {
  diagnosticResults.innerHTML =
    '<div style="color: #2196F3;">📖 Testing Firestore Read...</div>';

  try {
    const user = auth.currentUser;
    if (!user) {
      appendDiagnosticResult("Must be authenticated first", false);
      return;
    }

    // Try to read from schools collection
    const schoolsRef = collection(db, "schools");
    const schoolDoc = await getDoc(doc(schoolsRef, currentSchoolId));

    if (schoolDoc.exists()) {
      appendDiagnosticResult(`Read school doc: ${currentSchoolId}`, true);
      appendDiagnosticResult(
        `School data: ${JSON.stringify(schoolDoc.data()).substring(0, 100)}...`,
        true
      );
    } else {
      appendDiagnosticResult(
        `School doc ${currentSchoolId} not found (may need to be created)`,
        false
      );
    }

    // Try to read from login-pictures
    const loginPicsRef = collection(
      db,
      "schools",
      currentSchoolId,
      "login-pictures"
    );
    const q = query(loginPicsRef, limit(1));
    const querySnapshot = await getDocs(q);

    if (!querySnapshot.empty) {
      appendDiagnosticResult(
        `Read login-pictures: Found ${querySnapshot.size} document(s)`,
        true
      );
    } else {
      appendDiagnosticResult(
        `No documents in login-pictures yet (this is OK)`,
        true
      );
    }
  } catch (error) {
    appendDiagnosticResult(`Read Test Failed: ${error.message}`, false);
    console.error("Read test error:", error);
  }
}

async function runFirestoreWriteTest() {
  diagnosticResults.innerHTML =
    '<div style="color: #2196F3;">✍️ Testing Firestore Write...</div>';

  try {
    const user = auth.currentUser;
    if (!user) {
      appendDiagnosticResult("Must be authenticated first", false);
      return;
    }

    const testDocRef = collection(
      db,
      "schools",
      currentSchoolId,
      "login-pictures"
    );
    const testData = {
      test: true,
      timestamp: serverTimestamp(),
      userId: user.uid,
      userEmail: user.email,
      message: "Diagnostic test write",
    };

    appendDiagnosticResult(
      "Attempting write to /schools/" + currentSchoolId + "/login-pictures...",
      true
    );
    const docRef = await addDoc(testDocRef, testData);
    appendDiagnosticResult(`Write Success! Doc ID: ${docRef.id}`, true);

    // Clean up test document
    await deleteDoc(docRef);
    appendDiagnosticResult("Test document cleaned up", true);
  } catch (error) {
    appendDiagnosticResult(`Write Test Failed: ${error.message}`, false);
    appendDiagnosticResult(`Error code: ${error.code}`, false);
    console.error("Write test error:", error);
  }
}

async function runSchoolsTest() {
  diagnosticResults.innerHTML =
    '<div style="color: #2196F3;">🏫 Testing Schools Collection...</div>';

  try {
    const user = auth.currentUser;
    if (!user) {
      appendDiagnosticResult("Must be authenticated first", false);
      return;
    }

    // List all schools
    const schoolsRef = collection(db, "schools");
    const querySnapshot = await getDocs(schoolsRef);

    if (querySnapshot.empty) {
      appendDiagnosticResult("No schools found in database", false);
      appendDiagnosticResult(
        "You may need to create the school document first",
        false
      );
    } else {
      appendDiagnosticResult(`Found ${querySnapshot.size} school(s):`, true);
      querySnapshot.forEach((doc) => {
        appendDiagnosticResult(`  - ${doc.id}`, true);
      });

      // Check if our target school exists
      if (querySnapshot.docs.find((doc) => doc.id === currentSchoolId)) {
        appendDiagnosticResult(
          `✓ Target school "${currentSchoolId}" exists`,
          true
        );
      } else {
        appendDiagnosticResult(
          `✗ Target school "${currentSchoolId}" not found`,
          false
        );
      }
    }
  } catch (error) {
    appendDiagnosticResult(`Schools Test Failed: ${error.message}`, false);
    console.error("Schools test error:", error);
  }
}

/**
 * Cleanup on page unload
 */
window.addEventListener("beforeunload", () => {
  if (stream) {
    stream.getTracks().forEach((track) => track.stop());
  }
});
