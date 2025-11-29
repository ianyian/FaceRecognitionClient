// App State
const AppState = {
  currentScreen: "login",
  isLoggedIn: false,
  currentUser: null,
  schoolCode: "",
  isProcessing: false,
  lastCheckTime: null,
  lastStudent: null,
};

// Mock Data
const MOCK_USERS = {
  "staff@example.com": {
    password: "password123",
    name: "Ian Wong",
    role: "reception",
    schoolId: "main-tuition-center",
  },
  "admin@example.com": {
    password: "admin123",
    name: "Sarah Lee",
    role: "admin",
    schoolId: "main-tuition-center",
  },
};

const MOCK_STUDENTS = [
  { id: 1, name: "Ahmad Hassan", parent: "Mr. Hassan", phone: "+60123456789" },
  { id: 2, name: "Mei Ling Tan", parent: "Mrs. Tan", phone: "+60198765432" },
  { id: 3, name: "Kumar Raj", parent: "Mr. Kumar", phone: "+60187654321" },
];

// DOM Elements
const loginScreen = document.getElementById("loginScreen");
const cameraScreen = document.getElementById("cameraScreen");
const loginForm = document.getElementById("loginForm");
const schoolCodeInput = document.getElementById("schoolCode");
const emailInput = document.getElementById("email");
const passwordInput = document.getElementById("password");
const rememberMeCheckbox = document.getElementById("rememberMe");
const loginButtonText = document.getElementById("loginButtonText");
const loginSpinner = document.getElementById("loginSpinner");
const loginStatus = document.getElementById("loginStatus");
const staffNameDisplay = document.getElementById("staffName");
const logoutButton = document.getElementById("logoutButton");

// Initialize App
document.addEventListener("DOMContentLoaded", () => {
  loadSavedCredentials();
  setupEventListeners();
  checkAutoLogin();
});

// Load saved credentials from localStorage
function loadSavedCredentials() {
  const savedSchoolCode = localStorage.getItem("schoolCode");
  const savedEmail = localStorage.getItem("email");
  const rememberMe = localStorage.getItem("rememberMe") === "true";

  if (savedSchoolCode) {
    schoolCodeInput.value = savedSchoolCode;
  }

  if (rememberMe && savedEmail) {
    emailInput.value = savedEmail;
    rememberMeCheckbox.checked = true;
  }
}

// Check if auto-login is possible
function checkAutoLogin() {
  const savedEmail = localStorage.getItem("email");
  const rememberMe = localStorage.getItem("rememberMe") === "true";

  if (rememberMe && savedEmail && MOCK_USERS[savedEmail]) {
    // Simulate auto-login after a brief delay
    setTimeout(() => {
      const user = MOCK_USERS[savedEmail];
      loginSuccess(user, savedEmail);
    }, 1000);
  }
}

// Setup Event Listeners
function setupEventListeners() {
  loginForm.addEventListener("submit", handleLogin);
  logoutButton.addEventListener("click", handleLogout);
}

// Handle Login
async function handleLogin(e) {
  e.preventDefault();

  if (AppState.isProcessing) return;

  const schoolCode = schoolCodeInput.value.trim();
  const email = emailInput.value.trim();
  const password = passwordInput.value;
  const rememberMe = rememberMeCheckbox.checked;

  // Validate inputs
  if (!schoolCode || !email || !password) {
    showLoginError("Please fill in all fields");
    return;
  }

  // Show loading state
  setLoginLoading(true);

  // Simulate API call delay
  await sleep(1500);

  // Check credentials
  const user = MOCK_USERS[email];
  if (!user || user.password !== password) {
    setLoginLoading(false);
    showLoginError("Invalid email or password");
    vibrate([100, 50, 100]);
    return;
  }

  // Save credentials if remember me is checked
  if (rememberMe) {
    localStorage.setItem("schoolCode", schoolCode);
    localStorage.setItem("email", email);
    localStorage.setItem("rememberMe", "true");
  } else {
    localStorage.removeItem("email");
    localStorage.removeItem("rememberMe");
  }

  // Always save school code
  localStorage.setItem("schoolCode", schoolCode);

  // Login success
  loginSuccess(user, email);
}

// Login Success
function loginSuccess(user, email) {
  AppState.isLoggedIn = true;
  AppState.currentUser = user;
  AppState.schoolCode = localStorage.getItem("schoolCode");

  // Update UI
  staffNameDisplay.textContent = `Staff: ${user.name}`;

  // Show success message
  showLoginSuccess("Login successful!");

  // Transition to camera screen
  setTimeout(() => {
    switchScreen("camera");
    setLoginLoading(false);
    loginForm.reset();
    loginStatus.textContent = "";
    loginStatus.className = "status-message";

    // Start camera simulation
    startCameraSimulation();
  }, 800);

  vibrate([50, 30, 50]);
}

// Handle Logout
function handleLogout() {
  if (confirm("Are you sure you want to logout?")) {
    AppState.isLoggedIn = false;
    AppState.currentUser = null;

    // Reset camera screen
    resetCameraScreen();

    // Switch to login screen
    switchScreen("login");

    vibrate([100]);
  }
}

// Switch Screen
function switchScreen(screen) {
  loginScreen.classList.remove("active");
  cameraScreen.classList.remove("active");

  if (screen === "login") {
    loginScreen.classList.add("active");
    AppState.currentScreen = "login";
  } else if (screen === "camera") {
    cameraScreen.classList.add("active");
    AppState.currentScreen = "camera";
  }
}

// Login UI Helpers
function setLoginLoading(loading) {
  AppState.isProcessing = loading;

  if (loading) {
    loginButtonText.classList.add("hidden");
    loginSpinner.classList.remove("hidden");
    loginForm.querySelectorAll("input, select, button").forEach((el) => {
      el.disabled = true;
    });
  } else {
    loginButtonText.classList.remove("hidden");
    loginSpinner.classList.add("hidden");
    loginForm.querySelectorAll("input, select, button").forEach((el) => {
      el.disabled = false;
    });
  }
}

function showLoginError(message) {
  loginStatus.textContent = message;
  loginStatus.className = "status-message error";
}

function showLoginSuccess(message) {
  loginStatus.textContent = message;
  loginStatus.className = "status-message success";
}

// Camera Screen Functions
function startCameraSimulation() {
  // Simulate scanning state
  simulateScanning();

  // Random face detection after 2-4 seconds
  const delay = 2000 + Math.random() * 2000;
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      simulateFaceDetected();
    }
  }, delay);
}

function resetCameraScreen() {
  document.getElementById("faceBox").classList.add("hidden");
  document.getElementById("lastCheckTime").textContent = "-";
  document.getElementById("studentName").textContent = "-";
  document.getElementById("processingTime").textContent = "-";
  simulateScanning();
}

// Camera State Simulations (for demo)
window.simulateScanning = function () {
  updateCameraStatus(
    "scanning",
    "🔍",
    "Scanning...",
    "Position face in camera"
  );
  document.getElementById("faceBox").classList.add("hidden");
};

window.simulateFaceDetected = function () {
  updateCameraStatus("scanning", "👤", "Face Detected", "Hold still...");
  document.getElementById("faceBox").classList.remove("hidden");

  // Auto-proceed to processing
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      simulateProcessing();
    }
  }, 1000);
};

window.simulateProcessing = function () {
  updateCameraStatus("processing", "⏳", "Processing...", "Recognizing face");

  // Random result after 1-2 seconds
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      const success = Math.random() > 0.3; // 70% success rate
      if (success) {
        simulateSuccess();
      } else {
        simulateFailure();
      }
    }
  }, 1000 + Math.random() * 1000);
};

window.simulateSuccess = async function () {
  const student =
    MOCK_STUDENTS[Math.floor(Math.random() * MOCK_STUDENTS.length)];
  const processingTime = (Math.random() * 1.5 + 0.5).toFixed(2);

  updateCameraStatus("success", "✅", "Access OK", `Welcome, ${student.name}!`);

  // Update details
  const now = new Date();
  document.getElementById("lastCheckTime").textContent = formatTime(now);
  document.getElementById("studentName").textContent = student.name;
  document.getElementById("processingTime").textContent = `${processingTime}s`;

  AppState.lastCheckTime = now;
  AppState.lastStudent = student;

  // Vibrate success pattern
  vibrate([50, 30, 50, 30, 50]);

  // Simulate WhatsApp notification
  await sleep(500);
  console.log(
    `📱 WhatsApp notification sent to ${student.parent} (${student.phone})`
  );
  console.log(`Message: "✅ ${student.name} checked in at ${formatTime(now)}"`);

  // Return to scanning after 3 seconds
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      simulateScanning();
      // Simulate next detection
      setTimeout(() => {
        if (AppState.currentScreen === "camera") {
          simulateFaceDetected();
        }
      }, 3000 + Math.random() * 2000);
    }
  }, 3000);
};

window.simulateFailure = function () {
  updateCameraStatus("error", "❌", "Access FAILED", "Face not recognized");
  document.getElementById("faceBox").classList.add("hidden");

  // Vibrate error pattern
  vibrate([100, 50, 100, 50, 100]);

  // Return to scanning after 2 seconds
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      simulateScanning();
    }
  }, 2000);
};

window.simulateNoFace = function () {
  updateCameraStatus(
    "error",
    "🚫",
    "No Face Detected",
    "Please position face in camera"
  );
  document.getElementById("faceBox").classList.add("hidden");

  vibrate([100]);

  // Return to scanning after 1.5 seconds
  setTimeout(() => {
    if (AppState.currentScreen === "camera") {
      simulateScanning();
    }
  }, 1500);
};

// Update Camera Status
function updateCameraStatus(state, icon, title, message) {
  const indicator = document.getElementById("statusIndicator");
  const iconEl = document.getElementById("statusIcon");
  const titleEl = document.getElementById("statusTitle");
  const messageEl = document.getElementById("statusMessage");

  // Remove all state classes
  indicator.classList.remove("scanning", "processing", "success", "error");

  // Add new state class
  indicator.classList.add(state);

  // Update content
  iconEl.textContent = icon;
  titleEl.textContent = title;
  messageEl.textContent = message;
}

// Helper Functions
function formatTime(date) {
  return date.toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function vibrate(pattern) {
  if ("vibrate" in navigator) {
    navigator.vibrate(pattern);
  }
}

// Console welcome message
console.log(
  "%c🎨 FaceCheck iOS Client - Mockup",
  "font-size: 20px; font-weight: bold; color: #007AFF;"
);
console.log(
  "%cUse the demo controls to test different UI states",
  "font-size: 14px; color: #666;"
);
console.log("%cTest credentials:", "font-weight: bold; margin-top: 10px;");
console.log("Email: staff@example.com, Password: password123");
console.log("Email: admin@example.com, Password: admin123");
