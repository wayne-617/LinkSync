// background.js

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getMessaging, onBackgroundMessage } from "firebase/messaging/sw";

// import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
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

// replace with event listener push
onBackgroundMessage(messaging, (payload) => {
  console.log('Message received. ', payload);
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