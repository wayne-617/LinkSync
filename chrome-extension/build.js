const esbuild = require("esbuild");

// Bundle background.js (service worker)
const backgroundBuild = esbuild.build({
  entryPoints: ["background.js"],
  bundle: true,
  outfile: "dist/background.js",
  format: "esm",       // Chrome MV3 service worker supports ES modules
  minify: false,
});

// Bundle popup.js (popup script)
const popupBuild = esbuild.build({
  entryPoints: ["popup.js"],
  bundle: true,
  outfile: "dist/popup.js",
  format: "esm",       // ES module for <script type="module">
  minify: false,
});

// Run both builds in parallel
Promise.all([backgroundBuild, popupBuild])
  .then(() => {
    console.log("✅ Build complete for background.js and popup.js");
  })
  .catch(() => process.exit(1));
