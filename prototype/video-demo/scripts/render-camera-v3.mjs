import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import puppeteer from 'puppeteer-core';
import { preview } from 'vite';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputDir = path.join(root, 'output');
const outputPath = path.join(
  outputDir,
  'inspectflow-threejs-camera-test-v3-10s.mp4',
);
const fps = 60;
const frames = 600;

await mkdir(outputDir, { recursive: true });

const server = await preview({
  root,
  logLevel: 'error',
  preview: { host: '127.0.0.1', port: 4192, strictPort: true },
});
const browser = await puppeteer.launch({
  executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
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
    String(fps),
    '-vcodec',
    'mjpeg',
    '-i',
    'pipe:0',
    '-an',
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
  await page.goto('http://127.0.0.1:4192/?mode=camera-v3', {
    waitUntil: 'networkidle0',
    timeout: 120000,
  });
  await page.waitForFunction(() => window.__scanDemoReady === true, {
    timeout: 120000,
  });

  for (let frame = 0; frame < frames; frame += 1) {
    await page.evaluate((nextFrame) => window.__seekFrame(nextFrame), frame);
    await page.waitForFunction(
      (expected) => window.__renderedFrame === expected,
      {},
      frame,
    );
    const jpeg = await page.screenshot({
      type: 'jpeg',
      quality: 95,
      captureBeyondViewport: false,
    });
    if (!encoder.stdin.write(jpeg)) {
      await new Promise((resolve) => encoder.stdin.once('drain', resolve));
    }
    if (frame % 60 === 0) {
      process.stdout.write(`Rendered ${frame / 60}s / 10s\n`);
    }
  }

  encoder.stdin.end();
  await new Promise((resolve, reject) => {
    encoder.once('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exited with ${code}`));
    });
    encoder.once('error', reject);
  });
  process.stdout.write(`Created ${outputPath}\n`);
} finally {
  await browser.close();
  await new Promise((resolve) => server.httpServer.close(resolve));
}
