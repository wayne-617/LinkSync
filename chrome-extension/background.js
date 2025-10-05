// background.js

console.log("Background script loaded.");

// This is a placeholder for where the FCM listener will go.
// For now, it does nothing, but the file is a valid service worker.
function initializeFCM() {
  console.log("FCM would be initialized here.");
  // TODO: Add your Firebase initialization and onBackgroundMessage listener here
  // when your backend is ready.
}

initializeFCM();

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