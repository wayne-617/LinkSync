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

// DOM Elements
const loginScreen = document.getElementById("login-screen")
const registerScreen = document.getElementById("register-screen")
const messagesScreen = document.getElementById("messages-screen")
const loginForm = document.getElementById("login-form")
const registerForm = document.getElementById("register-form")
const showRegisterBtn = document.getElementById("show-register-btn")
const backToLoginBtn = document.getElementById("back-to-login-btn")
const registerError = document.getElementById("register-error")
const logoutBtn = document.getElementById("logout-btn")
const tabButtons = document.querySelectorAll(".tab-btn")
const newMessagesTab = document.getElementById("new-tab")
const allMessagesTab = document.getElementById("all-tab")
const newMessagesList = document.getElementById("new-messages-list")
const allMessagesList = document.getElementById("all-messages-list")

// Check if user is logged in on load
window.chrome.storage.local.get(["isLoggedIn"], (result) => {
  if (result.isLoggedIn) {
    showMessagesScreen()
  }
})

// Login form submission
loginForm.addEventListener("submit", (e) => {
  e.preventDefault()
  const username = document.getElementById("username").value
  const password = document.getElementById("password").value

  // Simple validation (accept any credentials for demo)
  if (username && password) {
    window.chrome.storage.local.get(["registeredUser"], (userResult) => {
      if (
        userResult.registeredUser &&
        userResult.registeredUser.username === username &&
        userResult.registeredUser.password === password
      ) {
        window.chrome.storage.local.set({ isLoggedIn: true, username }, () => {
          showMessagesScreen()
        })
      } else {
        alert("Invalid username or password")
      }
    })
  }
})

// Logout
logoutBtn.addEventListener("click", () => {
  window.chrome.storage.local.set({ isLoggedIn: false }, () => {
    showLoginScreen()
  })
})

// Tab switching
tabButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const tabName = button.dataset.tab

    // Update active tab button
    tabButtons.forEach((btn) => btn.classList.remove("active"))
    button.classList.add("active")

    // Show corresponding tab content
    if (tabName === "new") {
      newMessagesTab.classList.remove("hidden")
      allMessagesTab.classList.add("hidden")
    } else {
      newMessagesTab.classList.add("hidden")
      allMessagesTab.classList.remove("hidden")
    }
  })
})

// Show login screen
function showLoginScreen() {
  loginScreen.classList.remove("hidden")
  registerScreen.classList.add("hidden")
  messagesScreen.classList.add("hidden")
  loginForm.reset()
  registerError.classList.add("hidden")
}

// Show register screen
function showRegisterScreen() {
  loginScreen.classList.add("hidden")
  registerScreen.classList.remove("hidden")
  messagesScreen.classList.add("hidden")
  registerForm.reset()
  registerError.classList.add("hidden")
}

// Show messages screen
function showMessagesScreen() {
  loginScreen.classList.add("hidden")
  registerScreen.classList.add("hidden")
  messagesScreen.classList.remove("hidden")
  renderMessages()
}

// Render messages from chrome.storage
function renderMessages() {
  chrome.storage.local.get({ items: [] }, (result) => {
    const allMessages = result.items;
    // For now, we'll treat all messages as "new" for simplicity.
    const newMessages = allMessages;

    // Render new messages
    if (newMessages.length === 0) {
      newMessagesList.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">📭</div>
          <div class="empty-state-text">No new items</div>
        </div>
      `;
    } else {
      newMessagesList.innerHTML = newMessages.map((msg) => createMessageHTML(msg)).join("");
    }

    // Render all messages
    allMessagesList.innerHTML = allMessages.map((msg) => createMessageHTML(msg)).join("");
  });
}

// Create message HTML from storage item
function createMessageHTML(item) {
  // Use data structure from your backend (textPayload, type, timestamp)
  const preview = item.type === 'text' ? item.textPayload : `Media item: [${item.type}]`;
  const time = new Date(item.timestamp).toLocaleString();

  return `
    <div class="message-item">
      <div class="message-header">
        <span class="message-sender">
          New Item
          <span class="badge-new">NEW</span>
        </span>
        <span class="message-time">${time}</span>
      </div>
      <div class="message-subject">${item.type.charAt(0).toUpperCase() + item.type.slice(1)}</div>
      <div class="message-preview">${preview}</div>
    </div>
  `;
}

// Register form submission
registerForm.addEventListener("submit", (e) => {
  e.preventDefault()
  const username = document.getElementById("reg-username").value
  const password = document.getElementById("reg-password").value
  const confirmPassword = document.getElementById("reg-confirm-password").value

  // Validate passwords match
  if (password !== confirmPassword) {
    registerError.textContent = "Passwords do not match"
    registerError.classList.remove("hidden")
    return
  }

  // Store user credentials
  window.chrome.storage.local.set(
    {
      registeredUser: { username, password },
    },
    () => {
      // Go back to login screen after successful registration
      showLoginScreen()
      registerForm.reset()
    },
  )
})

// Register button click handler
showRegisterBtn.addEventListener("click", () => {
  showRegisterScreen()
})

// Back to login button click handler
backToLoginBtn.addEventListener("click", () => {
  showLoginScreen()
})

// Listen for changes in storage and reload the list
chrome.storage.onChanged.addListener((changes, namespace) => {
  if (namespace === 'local' && changes.items) {
    renderMessages();
  }
});