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
const messagesScreen = document.getElementById("messages-screen")
const loginForm = document.getElementById("login-form")
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
    window.chrome.storage.local.set({ isLoggedIn: true, username }, () => {
      showMessagesScreen()
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
  messagesScreen.classList.add("hidden")
  loginForm.reset()
}

// Show messages screen
function showMessagesScreen() {
  loginScreen.classList.add("hidden")
  messagesScreen.classList.remove("hidden")
  renderMessages()
}

// Render messages
function renderMessages() {
  const newMessages = mockMessages.filter((msg) => msg.isNew)
  const allMessages = mockMessages

  // Render new messages
  if (newMessages.length === 0) {
    newMessagesList.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">📭</div>
        <div class="empty-state-text">No new messages</div>
      </div>
    `
  } else {
    newMessagesList.innerHTML = newMessages.map((msg) => createMessageHTML(msg)).join("")
  }

  // Render all messages
  allMessagesList.innerHTML = allMessages.map((msg) => createMessageHTML(msg)).join("")
}

// Create message HTML
function createMessageHTML(message) {
  return `
    <div class="message-item ${message.isNew ? "" : "read"}">
      <div class="message-header">
        <span class="message-sender">
          ${message.sender}
          ${message.isNew ? '<span class="badge-new">NEW</span>' : ""}
        </span>
        <span class="message-time">${message.time}</span>
      </div>
      <div class="message-subject">${message.subject}</div>
      <div class="message-preview">${message.preview}</div>
    </div>
  `
}