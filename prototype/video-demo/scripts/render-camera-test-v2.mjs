import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const assetDir = path.join(root, 'public', 'assets', 'camera-test-v2');
const outputDir = path.join(root, 'output');
const outputPath = path.join(outputDir, 'inspectflow-camera-only-test-v2-10s.mp4');

await mkdir(outputDir, { recursive: true });

const images = [
  ['00-side.png', '3.0'],
  ['01-shallow-front-left.png', '2.0'],
  ['03-front.png', '5.6'],
];

const inputArgs = images.flatMap(([filename, duration]) => [
  '-loop',
  '1',
  '-framerate',
  '60',
  '-t',
  duration,
  '-i',
  path.join(assetDir, filename),
]);

const normalize =
  'scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,fps=60,format=yuv420p';
const filter = [
  `[0:v]${normalize}[side]`,
  `[1:v]${normalize}[shallow]`,
  `[2:v]${normalize}[front]`,
  '[side][shallow]xfade=transition=fade:duration=0.3:offset=2.7[first]',
  '[first][front]xfade=transition=fade:duration=0.3:offset=4.4[composite]',
  "[composite]gblur=sigma=16:steps=2:enable='between(t,2.58,3.02)+between(t,4.28,4.72)',tmix=frames=3:weights='1 2 1'[out]",
].join(';');

const args = [
  '-y',
  ...inputArgs,
  '-filter_complex',
  filter,
  '-map',
  '[out]',
  '-an',
  '-r',
  '60',
  '-frames:v',
  '600',
  '-c:v',
  'libx264',
  '-preset',
  'medium',
  '-crf',
  '17',
  '-pix_fmt',
  'yuv420p',
  '-movflags',
  '+faststart',
  outputPath,
];

const encoder = spawn('ffmpeg', args, { stdio: 'inherit' });
const exitCode = await new Promise((resolve, reject) => {
  encoder.once('close', resolve);
  encoder.once('error', reject);
});

if (exitCode !== 0) throw new Error(`ffmpeg exited with ${exitCode}`);
process.stdout.write(`Created ${outputPath}\n`);
