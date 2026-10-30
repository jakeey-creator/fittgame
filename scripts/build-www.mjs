// Baut den Web-Ordner für die iOS-App (www/): index.html + MediaPipe, Pose-Modell und Schrift lokal,
// damit die App komplett offline läuft.
import { cp, mkdir, readFile, writeFile, rm, access } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(root, 'www');
const vendor = join(www, 'vendor');
const MODEL_URL = 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task';
const modelCache = join(root, 'assets', 'pose_landmarker_lite.task');

await rm(www, { recursive: true, force: true });
await mkdir(join(vendor, 'mediapipe'), { recursive: true });

// MediaPipe (JS-Bundle + WASM)
const mp = join(root, 'node_modules', '@mediapipe', 'tasks-vision');
await cp(join(mp, 'vision_bundle.mjs'), join(vendor, 'mediapipe', 'vision_bundle.mjs'));
await cp(join(mp, 'wasm'), join(vendor, 'mediapipe', 'wasm'), { recursive: true });

// Pose-Modell (einmal herunterladen, dann aus assets/ nehmen)
try { await access(modelCache); } catch {
  console.log('Lade Pose-Modell …');
  const res = await fetch(MODEL_URL);
  if (!res.ok) throw new Error(`Modell-Download fehlgeschlagen: ${res.status}`);
  await mkdir(dirname(modelCache), { recursive: true });
  await writeFile(modelCache, Buffer.from(await res.arrayBuffer()));
}
await cp(modelCache, join(vendor, 'pose_landmarker_lite.task'));

// Schrift „Baloo 2“ lokal statt Google Fonts
const fontDir = join(root, 'node_modules', '@fontsource', 'baloo-2', 'files');
await mkdir(join(vendor, 'fonts'), { recursive: true });
let css = '';
for (const w of [600, 700, 800]){
  const f = `baloo-2-latin-${w}-normal.woff2`;
  await cp(join(fontDir, f), join(vendor, 'fonts', f));
  css += `@font-face{font-family:'Baloo 2';font-style:normal;font-weight:${w};font-display:swap;src:url(fonts/${f}) format('woff2')}\n`;
}
await writeFile(join(vendor, 'fonts.css'), css);

let html = await readFile(join(root, 'index.html'), 'utf8');
html = html.replace(/<link rel="preconnect"[^>]*>\n/g, '')
           .replace(/<link href="https:\/\/fonts\.googleapis\.com[^>]*>/, '<link rel="stylesheet" href="vendor/fonts.css">');
if (html.includes('fonts.googleapis.com')) throw new Error('Google-Fonts-Link nicht ersetzt');
await writeFile(join(www, 'index.html'), html);
console.log('www/ gebaut.');
