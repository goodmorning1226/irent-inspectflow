import { useEffect, useLayoutEffect, useState } from 'react';

import { CameraOnlySceneV3 } from './CameraOnlySceneV3';

const FPS = 60;
const DURATION = 10;

export function CameraOnlyApp() {
  const [frame, setFrame] = useState(0);
  const [sceneReady, setSceneReady] = useState(false);

  useEffect(() => {
    window.__seekFrame = (nextFrame) => setFrame(nextFrame);
    window.__videoSpec = { fps: FPS, duration: DURATION, frames: FPS * DURATION };
    return () => delete window.__seekFrame;
  }, []);

  useLayoutEffect(() => {
    window.__renderedFrame = frame;
  }, [frame]);

  useEffect(() => {
    window.__scanDemoReady = sceneReady;
  }, [sceneReady]);

  return (
    <main className="camera-only-frame">
      <CameraOnlySceneV3
        frame={frame}
        fps={FPS}
        onReady={() => setSceneReady(true)}
      />
    </main>
  );
}
