import React from 'react';
import { createRoot } from 'react-dom/client';

import { App } from './App';
import { CameraOnlyApp } from './CameraOnlyApp';
import './styles.css';

const cameraOnly = new URLSearchParams(window.location.search).get('mode') === 'camera-v3';

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    {cameraOnly ? <CameraOnlyApp /> : <App />}
  </React.StrictMode>,
);
