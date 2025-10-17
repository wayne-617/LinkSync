// background.js

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getMessaging } from "firebase/messaging/sw";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDv0e1JvUbtNqfT1fa0q0bsSWwhaSfkSRA",
  authDomain: "linksync-10854.firebaseapp.com",
  projectId: "linksync-10854",
  storageBucket: "linksync-10854.firebasestorage.app",
  messagingSenderId: "861936914311",
  appId: "1:861936914311:web:0b4162597be16202c28d22",
  measurementId: "G-H6Q1ZGTJ6V"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

console.log("Background script loaded.");

// Handle background messages from Firebase
self.addEventListener('push', (event) => {
  console.log("Push event received:", event);

  // Safely get payload (works with FCM data-only messages)
  let payload = {};
  try {
    payload = event.data?.json?.() || {};
  } catch (e) {
    console.warn("Failed to parse push payload:", e);
  }

  console.log("Payload:", payload);

  const title = payload.data?.title || "New Notification";
  const body = payload.data?.body || "You have a new message!";
  const link = payload.data?.link || null;

  console.log("Notification values:", { title, body, link });

  event.waitUntil(
    Promise.resolve().then(() => {
      return self.registration.showNotification(title, {
        body,
        data: { link },
        requireInteraction: false,
        tag: "linksync-notification"
      });
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  console.log("Notification clicked:", event);
  event.notification.close();

  const link = event.notification.data?.link;
  console.log("Opening link:", link);

  if (link) {
    event.waitUntil(
      clients.matchAll({ type: "window", includeUncontrolled: true })
        .then((clientList) => {
          for (let client of clientList) {
            if (client.url === link && "focus" in client) {
              return client.focus();
            }
          }
          return clients.openWindow(link);
        })
    );
  }
});

// This function will fetch data from your backend.
async function fetchItemFromBackend(itemId) {
  console.log(`Fetching item ${itemId} from backend...`);
  // TODO: Replace with your actual API endpoint and authentication logic.
  // For now, we'll return a mock item.
  return {
    id: itemId,
    type: 'text',
    textPayload: `This is the content for item ${itemId} fetched from the backend.`,
    timestamp: new Date().toISOString()
  };
}

// This function saves the fetched item into Chrome's local storage.
async function saveItemToStorage(newItem) {
  // chrome.storage.local.get reads the current list of items.
  chrome.storage.local.get({ items: [] }, (result) => {
    const existingItems = result.items;
    // Add the new item to the beginning of the array.
    const updatedItems = [newItem, ...existingItems];
    // chrome.storage.local.set saves the updated list.
    chrome.storage.local.set({ items: updatedItems }, () => {
      console.log("Item saved to storage:", newItem);
    });
  });
}

// You can use this function to test the flow from the browser's developer console.
// For example: chrome.runtime.getBackgroundPage(p => p.simulateNotification("test-123"))
function simulateNotification(itemId) {
  console.log(`Simulating notification for itemId: ${itemId}`);
  fetchItemFromBackend(itemId)
    .then(item => {
      saveItemToStorage(item);
    });
}