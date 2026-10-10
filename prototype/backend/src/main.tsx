import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import { App } from './app/App';
import { AppErrorBoundary } from './app/AppErrorBoundary';
import './styles/index.css';

const root = document.getElementById('root');

if (!root) {
  throw new Error('找不到應用程式根節點。');
}

createRoot(root).render(
  <StrictMode>
    <AppErrorBoundary>
      <App />
    </AppErrorBoundary>
  </StrictMode>,
);
