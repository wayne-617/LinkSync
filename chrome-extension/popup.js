// Mock messages data
const mockMessages = [
  {
    id: 1,
    sender: "Sarah Johnson",
    subject: "Project Update",
    preview: "Hey! Just wanted to give you a quick update on the project progress...",
    time: "2 min ago",
    isNew: true,
  },
  {
    id: 2,
    sender: "Mike Chen",
    subject: "Meeting Tomorrow",
    preview: "Don't forget about our meeting tomorrow at 10 AM. See you there!",
    time: "15 min ago",
    isNew: true,
  },
  {
    id: 3,
    sender: "Emily Davis",
    subject: "Design Review",
    preview: "I've reviewed the latest designs and have some feedback to share...",
    time: "1 hour ago",
    isNew: true,
  },
  {
    id: 4,
    sender: "Alex Martinez",
    subject: "Welcome to the Team",
    preview: "Welcome aboard! We're excited to have you join our team...",
    time: "Yesterday",
    isNew: false,
  },
  {
    id: 5,
    sender: "Jessica Lee",
    subject: "Invoice #1234",
    preview: "Please find attached the invoice for this month's services...",
    time: "2 days ago",
    isNew: false,
  },
  {
    id: 6,
    sender: "David Brown",
    subject: "Quick Question",
    preview: "Do you have a moment to discuss the requirements for the new feature?",
    time: "3 days ago",
    isNew: false,
  },
]

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

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// ---------- Storage Helpers ----------
function chromeGet(keys) {
  return new Promise((resolve) => chrome.storage.local.get(keys, resolve));
}

function chromeSet(data) {
  return new Promise((resolve) => chrome.storage.local.set(data, resolve));
}

// ---------- AuthContext-like Object ----------
const Auth = {
  user: null,

  async init() {
    const { isLoggedIn, registeredUser } = await chromeGet(["isLoggedIn", "registeredUser"]);
    if (isLoggedIn && registeredUser) {
      this.user = registeredUser;
      showView("messages-screen");
      renderMessages();
    } else {
      showView("login-screen");
    }
  },

  async login(username, password) {
    const { registeredUser } = await chromeGet(["registeredUser"]);
    if (registeredUser && registeredUser.username === username && registeredUser.password === password) {
      this.user = registeredUser;
      await chromeSet({ isLoggedIn: true, username });
      showView("messages-screen");
      renderMessages();
    } else {
      alert("Invalid username or password");
    }
  },

  async logout() {
    this.user = null;
    await chromeSet({ isLoggedIn: false });
    showView("login-screen");
  },

  async register(username, password) {
    await chromeSet({ registeredUser: { username, password } });
    showView("login-screen");
  },
};

// ---------- View Management ----------
function showView(viewId) {
  document.querySelectorAll(".screen").forEach((screen) => {
    screen.classList.add("hidden");
  });
  document.getElementById(viewId).classList.remove("hidden");
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
  const username = document.getElementById("username").value;
  const password = document.getElementById("password").value;
  await Auth.login(username, password);
});

document.getElementById("register-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const username = document.getElementById("reg-username").value;
  const password = document.getElementById("reg-password").value;
  const confirm = document.getElementById("reg-confirm-password").value;
  const registerError = document.getElementById("register-error");

  if (password !== confirm) {
    registerError.textContent = "Passwords do not match";
    registerError.classList.remove("hidden");
    return;
  }

  registerError.classList.add("hidden");

  // Request FCM permission + get token
  const permission = await Notification.requestPermission();
  if (permission === "granted") {
    const registration = await navigator.serviceWorker.getRegistration();
    const token = await getToken(messaging, {
      vapidKey: "BHZr6p9au9aassV7zioGX2u2R9nQ1e4QYSLrrbZ5gavgrTM5Z1_K4tDgfcEK2U0tng3SnCOVw6BXtDAAk7n-XUA",
      serviceWorkerRegistration: registration,
    });
    await chromeSet({ fcmToken: token });
  }

  await Auth.register(username, password);
  document.getElementById("register-form").reset();
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