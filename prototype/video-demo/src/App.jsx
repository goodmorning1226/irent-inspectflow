import { useEffect, useLayoutEffect, useMemo, useState } from 'react';

import { ScanScene } from './ScanScene';

const FPS = 60;
const DURATION = 10;

const clamp = (value, min = 0, max = 1) =>
  Math.min(max, Math.max(min, value));

function smoothstep(value) {
  const x = clamp(value);
  return x * x * (3 - 2 * x);
}

function getTimeline(time) {
  const sideProgress = smoothstep((time - 0.9) / 2.5);
  const sideComplete = time >= 3.6;
  const walking = time >= 4.2 && time < 7.15;
  const frontProgress = smoothstep((time - 7.25) / 2.1);
  const frontComplete = time >= 9.45;

  if (time < 0.7) {
    return {
      title: '正在尋找車輛',
      detail: '請將車身保持在畫面中央',
      zone: null,
      quality: 0,
      sideComplete: false,
      frontComplete: false,
      walking: false,
    };
  }
  if (!sideComplete) {
    return {
      title: '已辨識：左側',
      detail: sideProgress < 0.72 ? '保持距離，系統正在鎖定影像' : '影像品質穩定',
      zone: 'left',
      quality: sideProgress,
      sideComplete: false,
      frontComplete: false,
      walking: false,
    };
  }
  if (walking) {
    return {
      title: '左側掃描完成',
      detail: '請沿車身前往車頭',
      zone: 'front',
      quality: 0,
      sideComplete: true,
      frontComplete: false,
      walking: true,
    };
  }
  return {
    title: frontComplete ? '車頭掃描完成' : '已辨識：車頭',
    detail: frontComplete ? '請繼續前往右側' : '保持位置，正在自動擷取',
    zone: 'front',
    quality: frontProgress,
    sideComplete: true,
    frontComplete,
    walking: false,
  };
}

function CoverageMap({ timeline }) {
  const stateClass = (zone) => {
    if (zone === 'left' && timeline.sideComplete) return 'complete';
    if (zone === 'front' && timeline.frontComplete) return 'complete';
    if (timeline.zone === zone) return timeline.walking ? 'next' : 'active';
    return 'pending';
  };

  return (
    <div className="coverage-card">
      <div className="coverage-card__header">
        <span>全車掃描</span>
        <strong>{timeline.frontComplete ? '2' : timeline.sideComplete ? '1' : '0'} / 6</strong>
      </div>
      <svg aria-label="六區車況掃描進度" viewBox="0 0 260 168">
        <path className={`zone zone--front ${stateClass('front')}`} d="M76 32 Q130 5 184 32 L178 51 L82 51 Z" />
        <path className="zone pending" d="M82 117 L178 117 L184 137 Q130 163 76 137 Z" />
        <path className={`zone zone--left ${stateClass('left')}`} d="M52 51 L82 51 L82 117 L52 117 Q42 84 52 51 Z" />
        <path className="zone pending" d="M178 51 L208 51 Q218 84 208 117 L178 117 Z" />
        <rect className="zone pending" x="84" y="53" width="92" height="30" rx="5" />
        <rect className="zone pending" x="84" y="85" width="92" height="30" rx="5" />
        <path className="car-outline" d="M76 32 Q130 5 184 32 L208 51 Q218 84 208 117 L184 137 Q130 163 76 137 L52 117 Q42 84 52 51 Z" />
      </svg>
      <div className="coverage-card__legend">
        <i className="legend-dot legend-dot--active" />
        <span>{timeline.walking ? '下一區：車頭' : timeline.title}</span>
      </div>
    </div>
  );
}

function ScanReticle({ timeline }) {
  const percent = Math.round(timeline.quality * 100);
  return (
    <div className={`reticle ${timeline.walking ? 'reticle--walking' : ''}`}>
      <i className="corner corner--tl" />
      <i className="corner corner--tr" />
      <i className="corner corner--bl" />
      <i className="corner corner--br" />
      {!timeline.walking && timeline.zone && (
        <div className="quality-lock">
          <span>品質鎖定</span>
          <strong>{percent}%</strong>
          <div><i style={{ width: `${percent}%` }} /></div>
        </div>
      )}
    </div>
  );
}

export function App() {
  const [frame, setFrame] = useState(0);
  const [sceneReady, setSceneReady] = useState(false);
  const time = frame / FPS;
  const timeline = useMemo(() => getTimeline(time), [time]);

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
    <main className="demo-frame">
      <ScanScene frame={frame} fps={FPS} onReady={() => setSceneReady(true)} />
      <div className="camera-vignette" />
      <div className="scan-sweep" style={{ '--frame': frame }} />
      <header className="hud-header">
        <div className="brand-block">
          <span className="brand-mark">iRent</span>
          <div>
            <strong>AI 車況掃描</strong>
            <small>自動辨識區域與影像品質</small>
          </div>
        </div>
        <span className="prototype-badge">Prototype 模擬結果</span>
      </header>
      <section className="status-panel">
        <span className={`status-icon ${timeline.walking ? 'is-walking' : ''}`}>
          {timeline.walking ? '→' : '◎'}
        </span>
        <div>
          <strong>{timeline.title}</strong>
          <span>{timeline.detail}</span>
        </div>
      </section>
      <ScanReticle timeline={timeline} />
      <CoverageMap timeline={timeline} />
      <footer className="hud-footer">
        <span className="record-dot" />
        <span>系統會在品質穩定時自動保存最佳影格</span>
      </footer>
    </main>
  );
}
