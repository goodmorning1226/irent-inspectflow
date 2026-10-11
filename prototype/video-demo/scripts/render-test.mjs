import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import puppeteer from 'puppeteer-core';
import { preview } from 'vite';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputDir = path.join(root, 'output');
const outputPath = path.join(outputDir, 'inspectflow-scan-test-10s-final.mp4');
const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const timelineFps = 60;
const captureFps = 30;
const frames = 300;

await mkdir(outputDir, { recursive: true });

const server = await preview({
  root,
  logLevel: 'error',
  preview: { host: '127.0.0.1', port: 4190, strictPort: true },
});

const browser = await puppeteer.launch({
  executablePath: chromePath,
  headless: true,
  defaultViewport: { width: 1920, height: 1080, deviceScaleFactor: 1 },
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--hide-scrollbars',
    '--enable-webgl',
  ],
});

const encoder = spawn(
  'ffmpeg',
  [
    '-y',
    '-f',
    'image2pipe',
    '-framerate',
    String(captureFps),
    '-vcodec',
    'mjpeg',
    '-i',
    'pipe:0',
    '-an',
    '-vf',
    'scale=1920:1080:flags=lanczos,minterpolate=fps=60:mi_mode=blend,tpad=stop_mode=clone:stop_duration=0.05',
    '-c:v',
    'libx264',
    '-preset',
    'medium',
    '-crf',
    '18',
    '-pix_fmt',
    'yuv420p',
    '-movflags',
    '+faststart',
    outputPath,
  ],
  { stdio: ['pipe', 'inherit', 'inherit'] },
);

try {
  const page = await browser.newPage();
  await page.goto('http://127.0.0.1:4190', { waitUntil: 'networkidle0' });
  await page.waitForFunction(() => window.__scanDemoReady === true, { timeout: 120000 });

  for (let frame = 0; frame < frames; frame += 1) {
    const timelineFrame = frame * (timelineFps / captureFps);
    await page.evaluate((nextFrame) => window.__seekFrame(nextFrame), timelineFrame);
    await page.waitForFunction((expected) => window.__renderedFrame === expected, {}, timelineFrame);
    const jpeg = await page.screenshot({ type: 'jpeg', quality: 94, captureBeyondViewport: false });
    if (!encoder.stdin.write(jpeg)) {
      await new Promise((resolve) => encoder.stdin.once('drain', resolve));
    }
    if (frame % 30 === 0) process.stdout.write(`Rendered ${frame / 30}s / 10s\n`);
  }
  encoder.stdin.end();
  await new Promise((resolve, reject) => {
    encoder.once('close', (code) => (code === 0 ? resolve() : reject(new Error(`ffmpeg exited with ${code}`))));
    encoder.once('error', reject);
  });
  process.stdout.write(`Created ${outputPath}\n`);
} finally {
  await browser.close();
  await new Promise((resolve) => server.httpServer.close(resolve));
}
