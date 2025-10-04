console.log("Background service worker running...");
chrome.action.setBadgeBackgroundColor({ color: "#FF0000" });
chrome.action.setBadgeText({ text: "0" });

// This script will handle listening for FCM messages
chrome.gcm.onMessage.addListener((message) => {
  console.log('FCM message received:', message);
  // We'll add fetching logic here in the next step
});