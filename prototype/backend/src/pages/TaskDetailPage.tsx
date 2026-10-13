import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import { buildCaseWorkspace } from '../domain/caseEvidence';
import {
  buildTaskWorkspace,
  taskStatusLabels,
  taskTypeLabels,
} from '../domain/taskRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function TaskDetailPage() {
  const { taskId = '' } = useParams();
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const requestClaim = useInspectFlowStore((state) => state.requestClaim);
  const workspace = useMemo(
    () => buildTaskWorkspace(taskId, dataset),
    [dataset, taskId],
  );
  const caseWorkspace = useMemo(
    () =>
      workspace
        ? buildCaseWorkspace(workspace.currentCase.id, workspace.dataset)
        : null,
    [workspace],
  );
  const [activeZoneId, setActiveZoneId] = useState('front');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (workspace && dataset.meta.id !== workspace.dataset.meta.id) {
      loadScenario(workspace.dataset.meta.id);
    }
  }, [dataset.meta.id, loadScenario, workspace]);

  useEffect(() => {
    if (caseWorkspace) setActiveZoneId(caseWorkspace.defaultZoneId);
  }, [caseWorkspace?.defaultZoneId, taskId]);

  if (!workspace || !caseWorkspace || workspace.task.type === 'claim_review') {
    return (
      <div className="empty-state">
        <span className="empty-state__stage">找不到處理案件</span>
        <h2>{taskId}</h2>
        <Link className="button button--primary" to="/processing">
          返回處理中案件
        </Link>
      </div>
    );
  }

  const {
    task,
    currentCase,
    vehicle,
    finding,
    dataset: sourceDataset,
  } = workspace;
  const activeZone =
    caseWorkspace.zoneEvidence.find((zone) => zone.zoneId === activeZoneId) ??
    caseWorkspace.zoneEvidence[0];
  const claimRequested = sourceDataset.tasks.some(
    (item) =>
      item.caseId === currentCase.id &&
      item.type === 'claim_review' &&
      item.status !== 'CANCELLED',
  );

  return (
    <div className="page-stack simplified-detail">
      <header className="case-workspace-header">
        <div>
          <Link className="back-link" to="/processing">
            ← 返回處理中案件
          </Link>
          <p>
            {task.id}・{vehicle.plateNumber}
          </p>
          <h2>{task.title}</h2>
        </div>
      </header>

      <div className="processing-detail-layout">
        <main className="comparison-main">
          <section className="comparison-card zone-overview-card">
            <header className="simple-section-heading">
              <div>
                <p className="section-kicker">最近一次六區車況</p>
                <h3>選擇比對區域</h3>
              </div>
            </header>
            <div
              aria-label="車輛六區影像"
              className="zone-evidence-grid"
              role="tablist"
            >
              {caseWorkspace.zoneEvidence.map((zone) => (
                <button
                  aria-controls="processing-zone-comparison"
                  aria-selected={activeZone.zoneId === zone.zoneId}
                  className={`zone-evidence-tile${
                    activeZone.zoneId === zone.zoneId ? ' is-active' : ''
                  }`}
                  key={zone.zoneId}
                  onClick={() => setActiveZoneId(zone.zoneId)}
                  role="tab"
                  type="button"
                >
                  <span className="zone-evidence-tile__image">
                    {zone.current.src ? (
                      <img
                        alt={`${zone.zoneLabel}還車後影像`}
                        src={zone.current.src}
                      />
                    ) : (
                      <span className="zone-evidence-tile__missing">
                        無影像
                      </span>
                    )}
                  </span>
                  <span className="zone-evidence-tile__meta">
                    <strong>{zone.zoneLabel}</strong>
                    <small className={`zone-state zone-state--${zone.status}`}>
                      {zone.statusLabel}
                    </small>
                  </span>
                </button>
              ))}
            </div>
          </section>

          <section className="comparison-card">
            <header className="simple-section-heading">
              <div>
                <p className="section-kicker">同車、同區域</p>
                <h3>{activeZone.zoneLabel}・上次比對圖</h3>
              </div>
              <span
                className={`comparability comparability--${activeZone.comparability}`}
              >
                {activeZone.comparabilityLabel}
              </span>
            </header>
            <div
              className="comparison-grid"
              id="processing-zone-comparison"
              role="tabpanel"
            >
              <EvidenceImage evidence={activeZone.baseline} />
              <EvidenceImage evidence={activeZone.current} />
            </div>
          </section>

          {activeZone.angles.length > 0 && (
            <section className="comparison-card">
              <header className="simple-section-heading">
                <div>
                  <p className="section-kicker">補充證據</p>
                  <h3>異常特寫</h3>
                </div>
              </header>
              <div className="evidence-strip">
                {activeZone.angles.map((evidence) => (
                  <EvidenceImage evidence={evidence} key={evidence.id} />
                ))}
              </div>
            </section>
          )}
        </main>

        <aside className="processing-request-summary">
          <p className="section-kicker">車輛與處理資訊</p>
          <h3>{vehicle.plateNumber}</h3>
          <dl>
            <div>
              <dt>車型</dt>
              <dd>{vehicle.modelName}</dd>
            </div>
            <div>
              <dt>車色</dt>
              <dd>{vehicle.colorName}</dd>
            </div>
            <div>
              <dt>處理方式</dt>
              <dd>{taskTypeLabels[task.type]}</dd>
            </div>
            <div>
              <dt>案件進度</dt>
              <dd>{taskStatusLabels[task.status]}</dd>
            </div>
            <div>
              <dt>異常位置</dt>
              <dd>{finding?.location ?? '依案件內容確認'}</dd>
            </div>
            <div>
              <dt>車輛位置</dt>
              <dd>{task.location}</dd>
            </div>
          </dl>
          <button
            aria-disabled={claimRequested}
            className={`claim-request-button claim-request-button--large${
              claimRequested ? ' is-sent' : ''
            }`}
            onClick={() => {
              if (claimRequested) return;
              const result = requestClaim(currentCase.id);
              setMessage(result.message);
            }}
            type="button"
          >
            {claimRequested ? '已送出索賠請求' : '送出索賠請求'}
          </button>
          {message && <p className="action-message">{message}</p>}
        </aside>
      </div>
    </div>
  );
}
