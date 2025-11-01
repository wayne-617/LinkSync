// popup.js

import { initializeApp } from "firebase/app";
import { getMessaging, getToken } from "firebase/messaging";

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
const API_BASE_URL = process.env.AWS_API_URL;

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
      updateActionButton(); // Initialize button state
    } else {
      showView("login-screen");
    }
  },

  async login(username, password, fcm_token) {
    const data = await apiCall("/login", { username, password, fcm_token });
    const { accessToken, idToken, refreshToken } = data;
    if (!accessToken || !idToken || !refreshToken) {
      throw new Error("Missing tokens in response from API");
    }

    await chromeSet({
      authToken: accessToken,
      idToken,
      refreshToken
    });
    this.user = { authToken: accessToken, idToken, refreshToken };
    showView("messages-screen");
    renderMessages();
    updateActionButton(); // Initialize button state
  },

  async logout() {
    this.user = null;
    await chrome.storage.local.remove(["authToken"]);
    await chrome.storage.local.remove(["idToken"]);
    await chrome.storage.local.remove(["refreshToken"]);

    this.user = null;
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

// ---------- Banner Rendering ----------
function showSuccessBanner(message) {
  // Remove any existing banner
  const existingBanner = document.querySelector(".success-banner");
  if (existingBanner) {
    existingBanner.remove();
  }

  // Create new banner
  const banner = document.createElement("div");
  banner.className = "success-banner";
  banner.innerHTML = `<span>✓</span><span>${message}</span>`;
  document.body.appendChild(banner);

  // Auto-hide after 3 seconds
  setTimeout(() => {
    banner.classList.add("hide");
    setTimeout(() => banner.remove(), 300);
  }, 3000);
}

function showCopyBanner(message) {
  // Remove any existing banner
  const existingBanner = document.querySelector(".copy-banner");
  if (existingBanner) {
    existingBanner.remove();
  }

  // Create new banner
  const banner = document.createElement("div");
  banner.className = "copy-banner";
  banner.innerHTML = `<span>📋</span><span>${message}</span>`;
  document.body.appendChild(banner);

  // Auto-hide after 2 seconds
  setTimeout(() => {
    banner.classList.add("hide");
    setTimeout(() => banner.remove(), 300);
  }, 2000);
}

// ---------- Action Button Management ----------
function updateActionButton() {
  const actionBtn = document.getElementById("action-btn");
  const activeTab = document.querySelector(".tab-btn.active").dataset.tab;

  if (activeTab === "new") {
    actionBtn.textContent = "Mark All Read";
    actionBtn.className = "btn-action";
  } else {
    actionBtn.textContent = "Clear All";
    actionBtn.className = "btn-action clear";
  }
}

async function handleActionButton() {
  const activeTab = document.querySelector(".tab-btn.active").dataset.tab;
  const { items = [] } = await chromeGet(["items"]);

  if (activeTab === "new") {
    // Mark all as read
    const updatedItems = items.map(item => ({ ...item, seen: true }));
    await chromeSet({ items: updatedItems });
    showSuccessBanner("All messages marked as read");
  } else {
    // Clear all messages
    await chromeSet({ items: [] });
    showSuccessBanner("All messages cleared");
  }

  renderMessages();
}

// ---------- Message Rendering ----------
async function renderMessages() {
  const { items = [] } = await chromeGet(["items"]);
  const newMessagesList = document.getElementById("new-messages-list");
  const allMessagesList = document.getElementById("all-messages-list");

  const newItems = items.filter(m => !m.seen);
  const allItems = items;

  newMessagesList.innerHTML = newItems.length
    ? newItems.map(createMessageHTML).join("")
    : `<div class="empty-state"><div class="empty-state-icon">📭</div><div class="empty-state-text">No new items</div></div>`;

  allMessagesList.innerHTML = allItems.length
    ? allItems.map(createMessageHTML).join("")
    : `<div class="empty-state"><div class="empty-state-icon">📭</div><div class="empty-state-text">No messages</div></div>`;

  // Add click handlers after rendering
  document.querySelectorAll(".message-item").forEach((element) => {
    element.addEventListener("click", async () => {
      const id = element.dataset.id;
      const { items } = await chromeGet(["items"]);
      const target = items.find(m => m.id === id);
      if (!target) return;

      // Mark as seen
      target.seen = true;
      await chromeSet({ items });

      // Check if URL is a valid link
      if (target.url) {
        // Open link in new tab
        chrome.tabs.create({ url: target.url });
      } else {
        // Copy text to clipboard
        try {
          await navigator.clipboard.writeText(target.body);
          showCopyBanner("Copied to clipboard!");
        } catch (error) {
          console.error("Failed to copy:", error);
          showCopyBanner("Failed to copy");
        }
      }

      // Re-render UI
      renderMessages();
    });
  });
}

function createMessageHTML(item) {
  const time = new Date(item.timestamp).toLocaleString();
  const isNew = !item.seen ? '<span class="badge-new">NEW</span>' : '';
  let contentHtml = "";
  // Custom HTML structure for the URL item
  if (item.type === 'url') {
    const urlHostname = new URL(item.url).hostname;
    contentHtml = `
        <div class="message-header">
          <span class="message-sender">
            <span style="font-weight: bold;">${item.title || 'Shared Link'}</span> ${isNew}
          </span>
          <span class="message-time">${time}</span>
        </div>
        <div class="message-preview" style="margin-top: 5px; color: #3b82f6;">
          <span style="display: block; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; max-width: 90%;">
            ${item.url}
          </span>
          <span style="display: block; font-size: 0.75em; color: #9ca3af;">
            (${urlHostname})
          </span>
        </div>
    `;
  } else {
    // Original HTML structure for generic messages
    // ADDED inline style to ensure text wraps and breaks long words
    contentHtml = `
      <div class="message-header">
        <span class="message-sender">
          ${item.title} ${!item.seen ? '<span class="badge-new">NEW</span>' : ''}
        </span>
        <span class="message-time">${time}</span>
      </div>
      <div class="message-preview" style="word-wrap: break-word; overflow-wrap: break-word;">${item.body}</div>
    `;
  }
  return `
    <div class="message-item" data-id="${item.id}">
      ${contentHtml}
    </div>
  `;
}


// ---------- Event Listeners ----------
document.getElementById("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  clearError("login");

  const form = e.target;
  const button = form.querySelector("button[type='submit']");
  const inputs = form.querySelectorAll("input, button");

  const username = document.getElementById("username").value;
  const password = document.getElementById("password").value;

  try {
    // --- Disable UI + Show Spinner ---
    button.classList.add("loading");
    inputs.forEach((el) => (el.disabled = true));

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
    console.log("FCM Token:", fcm_token);
    // 2. Call login with all required data
    await Auth.login(username, password, fcm_token);

  } catch (error) {
    displayError("login", error.message);
  } finally {
    // --- Re-enable UI + Remove Spinner ---
    button.classList.remove("loading");
    inputs.forEach((el) => (el.disabled = false));
  }
});

// Register Form
document.getElementById("register-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  clearError("register");

  const form = e.target;
  const button = form.querySelector("button[type='submit']");
  const inputs = form.querySelectorAll("input, button");

  const username = document.getElementById("reg-username").value;
  const email = document.getElementById("reg-email").value;
  const password = document.getElementById("reg-password").value;
  const confirm = document.getElementById("reg-confirm-password").value;

  // --- Password Match Check ---
  if (password !== confirm) {
    displayError("register", "Passwords do not match");
    return;
  }

  // --- Password Strength Check ---
  const passwordPattern =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;

  if (!passwordPattern.test(password)) {
    displayError(
      "register",
      "Password must be at least 8 characters long and include at least one uppercase letter, one lowercase letter, one number, and one special character."
    );
    return;
  }

  try {
    // --- Disable UI + Show Spinner ---
    button.classList.add("loading");
    inputs.forEach((el) => (el.disabled = true));

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

    form.reset();
    showView("login-screen");
    showSuccessBanner("Registration successful! Please log in.");
  } catch (error) {
    // 4. Handle errors from API or token retrieval
    displayError("register", error.message);
  } finally {
    // --- Re-enable UI + Remove Spinner ---
    button.classList.remove("loading");
    inputs.forEach((el) => (el.disabled = false));
  }
});



document.getElementById("logout-btn").addEventListener("click", () => Auth.logout());
document.getElementById("show-register-btn").addEventListener("click", () => showView("register-screen"));
document.getElementById("back-to-login-btn").addEventListener("click", () => showView("login-screen"));

// Action Button (Mark All Read / Clear All)
document.getElementById("action-btn").addEventListener("click", handleActionButton);

// ---------- Tabs ----------
document.querySelectorAll(".tab-btn").forEach((button) => {
  button.addEventListener("click", () => {
    const tab = button.dataset.tab;
    document.querySelectorAll(".tab-btn").forEach((b) => b.classList.remove("active"));
    button.classList.add("active");

    document.getElementById("new-tab").classList.toggle("hidden", tab !== "new");
    document.getElementById("all-tab").classList.toggle("hidden", tab === "new");

    // Update action button text/style when tab changes
    updateActionButton();
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