// popup.js

import { initializeApp } from "firebase/app";
import { getMessaging, getToken } from "firebase/messaging";
import dotenv from "dotenv";

// ---------- Firebase Setup ----------
const firebaseConfig = {
  apiKey: "AIzaSyDv0e1JvUbtNqfT1fa0q0bsSWwhaSfkSRA",
  authDomain: "linksync-10854.firebaseapp.com",
  projectId: "linksync-10854",
  storageBucket: "linksync-10854.firebasestorage.app",
  messagingSenderId: "861936914311",
  appId: "1:861936914311:web:0b4162597be16202c28d22",
  measurementId: "G-H6Q1ZGTJ6V",
};

dotenv.config();

// dotenv is Node-only and can't be used in browser extension bundles.
// For browser usage, read config from a runtime-global (window.__env) or use a fallback.
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// ---------- Storage Helpers ----------
function chromeGet(keys) {
  return new Promise((resolve) => chrome.storage.local.get(keys, resolve));
}

function chromeSet(data) {
  return new Promise((resolve) => chrome.storage.local.set(data, resolve));
}

// ---------- API Helper ----------
// Use runtime-injected config (window.__env) if available, otherwise fall back to localhost.
const API_BASE_URL = (typeof window !== "undefined" && window.__env?.REACT_APP_API_URL) || "http://localhost:3000";
console.log("Using API URL:", API_BASE_URL);

async function apiCall(endpoint, body) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || `Error: ${response.status}`);
  }
  return data;
}

// ---------- Auth ----------
const Auth = {
  user: null,

  async init() {
    const { authToken } = await chromeGet(["authToken"]);
    if (authToken) {
      this.user = { token: authToken };
      showView("messages-screen");
      renderMessages();
    } else {
      showView("login-screen");
    }
  },

  async login(username, password) {
    const data = await apiCall("/login", { username, password });
    const token = data.token || data.idToken || data.accessToken;
    if (!token) throw new Error("No token returned from API");

    await chromeSet({ authToken: token });
    this.user = { token };
    showView("messages-screen");
    renderMessages();
  },

  async logout() {
    this.user = null;
    await chrome.storage.local.remove(["authToken"]);
    showView("login-screen");
  },

  // MODIFIED: Accepts all required fields for registration
  async register(username, email, password, fcm_token) {
    // Sends all data, including email and fcm_token, to the register endpoint
    await apiCall("/register", {
      username,
      email,
      password,
      fcm_token,
    });
  },
};

// ---------- View Management ----------
function showView(viewId) {
  document.querySelectorAll(".screen").forEach((screen) => {
    screen.classList.add("hidden");
  });
  document.getElementById(viewId).classList.remove("hidden");
}

function displayError(formId, message) {
  const errorEl = document.getElementById(`${formId}-error`);
  if (errorEl) {
    errorEl.textContent = message;
    errorEl.classList.remove("hidden");
  }
}

function clearError(formId) {
  const errorEl = document.getElementById(`${formId}-error`);
  if (errorEl && !errorEl.classList.contains("hidden")) {
    errorEl.classList.add("hidden");
  }
}

// ---------- Message Rendering ----------
async function renderMessages() {
  const { items = [] } = await chromeGet(["items"]);
  const newMessagesList = document.getElementById("new-messages-list");
  const allMessagesList = document.getElementById("all-messages-list");

  if (!items.length) {
    newMessagesList.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">📭</div>
        <div class="empty-state-text">No new items</div>
      </div>
    `;
    allMessagesList.innerHTML = "";
    return;
  }

  const html = items.map(createMessageHTML).join("");
  newMessagesList.innerHTML = html;
  allMessagesList.innerHTML = html;
}

function createMessageHTML(item) {
  const preview = item.type === "text" ? item.textPayload : `Media item: [${item.type}]`;
  const time = new Date(item.timestamp).toLocaleString();

  return `
    <div class="message-item">
      <div class="message-header">
        <span class="message-sender">
          New Item <span class="badge-new">NEW</span>
        </span>
        <span class="message-time">${time}</span>
      </div>
      <div class="message-subject">${item.type.charAt(0).toUpperCase() + item.type.slice(1)}</div>
      <div class="message-preview">${preview}</div>
    </div>
  `;
}

// ---------- Event Listeners ----------
document.getElementById("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  clearError("login");
  const username = document.getElementById("username").value;
  const password = document.getElementById("password").value;
  try {
    await Auth.login(username, password);
  } catch (error) {
    displayError("login", error.message);
  }
});

// MODIFIED: Handles new fields and a cleaner success/error flow
document.getElementById("register-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  clearError("register");

  const username = document.getElementById("reg-username").value;
  const email = document.getElementById("reg-email").value;
  const password = document.getElementById("reg-password").value;
  const confirm = document.getElementById("reg-confirm-password").value;

  if (password !== confirm) {
    displayError("register", "Passwords do not match");
    return;
  }

  try {
    // 1. Get FCM Token first
    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      throw new Error("Notification permission is required.");
    }

    const registration = await navigator.serviceWorker.getRegistration();
    const fcm_token = await getToken(messaging, {
      vapidKey: "BHZr6p9au9aassV7zioGX2u2R9nQ1e4QYSLrrbZ5gavgrTM5Z1_K4tDgfcEK2U0tng3SnCOVw6BXtDAAk7n-XUA",
      serviceWorkerRegistration: registration,
    });

    if (!fcm_token) {
      throw new Error("Could not retrieve FCM token.");
    }

    // 2. Call register with all required data
    await Auth.register(username, email, password, fcm_token);

    // 3. Handle success
    alert("✅ Registration successful! Please log in.");
    document.getElementById("register-form").reset();
    showView("login-screen");
  } catch (error) {
    // 4. Handle errors from API or token retrieval
    displayError("register", error.message);
  }
});

document.getElementById("logout-btn").addEventListener("click", () => Auth.logout());
document.getElementById("show-register-btn").addEventListener("click", () => showView("register-screen"));
document.getElementById("back-to-login-btn").addEventListener("click", () => showView("login-screen"));

// ---------- Tabs ----------
document.querySelectorAll(".tab-btn").forEach((button) => {
  button.addEventListener("click", () => {
    const tab = button.dataset.tab;
    document.querySelectorAll(".tab-btn").forEach((b) => b.classList.remove("active"));
    button.classList.add("active");

    document.getElementById("new-tab").classList.toggle("hidden", tab !== "new");
    document.getElementById("all-tab").classList.toggle("hidden", tab === "new");
  });
});

// ---------- Storage Change Listener ----------
chrome.storage.onChanged.addListener((changes, namespace) => {
  if (namespace === "local" && changes.items) {
    renderMessages();
  }
});

// ---------- Initialize ----------
Auth.init();