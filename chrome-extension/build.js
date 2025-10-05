// build.js
const esbuild = require('esbuild');

esbuild.build({
  entryPoints: ['background.js'], // your original background.js
  bundle: true,                       // bundle all imports
  outfile: 'dist/background.js',      // output file for Chrome
  format: 'esm',                      // use ES modules
  minify: false,                      // optional
}).catch(() => process.exit(1));
