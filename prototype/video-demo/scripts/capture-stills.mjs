import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import puppeteer from 'puppeteer-core';
import { preview } from 'vite';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const qaDir = path.join(root, 'qa');
await mkdir(qaDir, { recursive: true });

const server = await preview({
  root,
  logLevel: 'error',
  preview: { host: '127.0.0.1', port: 4188, strictPort: true },
});
const browser = await puppeteer.launch({
  executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  headless: true,
  defaultViewport: { width: 1920, height: 1080, deviceScaleFactor: 1 },
  args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-webgl'],
});

try {
  const page = await browser.newPage();
  await page.goto('http://127.0.0.1:4188', { waitUntil: 'networkidle0' });
  await page.waitForFunction(() => window.__scanDemoReady === true, { timeout: 120000 });
  for (const [name, frame] of [['side', 150], ['walking', 330], ['front', 520]]) {
    await page.evaluate((nextFrame) => window.__seekFrame(nextFrame), frame);
    await page.waitForFunction((expected) => window.__renderedFrame === expected, {}, frame);
    await page.screenshot({ path: path.join(qaDir, `${name}.png`), type: 'png' });
  }
} finally {
  await browser.close();
  await new Promise((resolve) => server.httpServer.close(resolve));
}
