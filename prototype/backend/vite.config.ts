import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const devSessionId = `${Date.now()}-${Math.random().toString(36).slice(2)}`;

export default defineConfig({
  plugins: [react()],
  define: {
    __INSPECTFLOW_DEV_SESSION_ID__: JSON.stringify(devSessionId),
  },
  publicDir: '../mobile/assets/frames',
  server: {
    port: 4173,
  },
  preview: {
    port: 4173,
  },
});
