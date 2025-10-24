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
self.addEventListener("push", (event) => {
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
  const timestamp = new Date().toISOString();
  const id = Date.now().toString(); // Track ID for seen state

  console.log("Notification values:", { title, body, link, id });

  event.waitUntil(
    chrome.storage.local.get({ items: [] }).then(({ items }) => {
      const newMessage = {
        id,
        title,
        body,
        url: link,
        type: "link",
        timestamp,
        seen: false,
      };
      const updatedItems = [newMessage, ...items];
      return chrome.storage.local.set({ items: updatedItems }).then(() => {
        // Show notification
        return self.registration.showNotification(title, {
          body,
          data: { link, id },
          requireInteraction: false,
          tag: `linksync-${id}`,
        });
      });
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  console.log("Notification clicked:", event);
  event.notification.close();

  const { link, id } = event.notification.data;
  console.log("Link data:", link);

  // Check if link is a valid URL
  const isValidUrl = link && (link.startsWith('http://') || link.startsWith('https://'));

  const openPromise = isValidUrl
    ? clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
        for (let client of clientList) {
          if (client.url === link && "focus" in client) {
            return client.focus();
          }
        }
        return clients.openWindow(link);
      })
    : Promise.resolve(); // Do nothing for text

  // Mark as seen in chrome.storage.local
  const markSeenPromise = chrome.storage.local.get({ items: [] }).then(({ items }) => {
    const updated = items.map((n) => (n.id === id ? { ...n, seen: true } : n));
    return chrome.storage.local.set({ items: updated });
  });

  event.waitUntil(Promise.all([openPromise, markSeenPromise]));
});
