document.addEventListener("DOMContentLoaded", () => {
  const loginBtn = document.getElementById("loginBtn");
  const logoutBtn = document.getElementById("logoutBtn");
  const itemsDiv = document.getElementById("items");

// Temporary fake items for demo
const demoItems = [
    { type: "text", content: "Hello from LinkSync!", time: new Date().toLocaleString() }
    // { type: "image", content: "https://via.placeholder.com/100", time: new Date().toLocaleString() }
];

  function renderItems() {
    itemsDiv.innerHTML = "";
    demoItems.forEach(item => {
      const div = document.createElement("div");
      div.className = "item";
      if (item.type === "text") {
        div.textContent = `${item.content} (${item.time})`;
      } else if (item.type === "image") {
        div.innerHTML = `<img src="${item.content}" width="100"/> (${item.time})`;
      }
      itemsDiv.appendChild(div);
    });
  }

  loginBtn.addEventListener("click", () => {
    alert("Login flow placeholder (Cognito later)");
    loginBtn.style.display = "none";
    logoutBtn.style.display = "inline-block";
  });

  logoutBtn.addEventListener("click", () => {
    alert("Logged out");
    loginBtn.style.display = "inline-block";
    logoutBtn.style.display = "none";
  });

  renderItems();
});
