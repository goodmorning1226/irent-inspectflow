import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import {
  buildCaseWorkspace,
  findingTypeLabels,
  formatFullDateTime,
  severityLabels,
} from '../domain/caseEvidence';
import { caseStatusLabels } from '../domain/caseRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function CaseDetailPage() {
  const { caseId = '' } = useParams();
  const activeDataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const workspace = useMemo(
    () => buildCaseWorkspace(caseId, activeDataset),
    [activeDataset, caseId],
  );
  const [activeZoneId, setActiveZoneId] = useState('front');

  useEffect(() => {
    if (workspace && activeDataset.meta.id !== workspace.dataset.meta.id) {
      loadScenario(workspace.dataset.meta.id);
    }
  }, [activeDataset.meta.id, loadScenario, workspace]);

  useEffect(() => {
    if (workspace) setActiveZoneId(workspace.defaultZoneId);
  }, [caseId, workspace?.defaultZoneId]);

  if (!workspace) {
    return (
      <div className="empty-state">
        <span className="empty-state__stage">找不到車況紀錄</span>
        <h2>{caseId}</h2>
        <Link className="button button--primary" to="/cases">
          返回車況清單
        </Link>
      </div>
    );
  }

  const {
    currentCase,
    vehicle,
    rental,
    findings,
    presentation,
    zoneEvidence,
    dataset,
  } = workspace;
  const activeZone =
    zoneEvidence.find((zone) => zone.zoneId === activeZoneId) ??
    zoneEvidence[0];
  const finding = findings[0];
  const task = dataset.tasks.find(
    (item) => item.caseId === currentCase.id && item.type !== 'claim_review',
  );
  const isClaimCandidate =
    finding?.possiblyNew === true &&
    ['scratch', 'dent', 'crack'].includes(finding.type);

  return (
    <div className="page-stack simplified-detail">
      <header className="case-workspace-header">
        <div>
          <Link className="back-link" to="/cases">
            ← 返回車況清單
          </Link>
          <p>
            {vehicle.plateNumber}・{currentCase.id}
          </p>
          <h2>{currentCase.title}</h2>
        </div>
        <div className="case-workspace-header__status">
          <span className={`risk-label risk-label--${currentCase.priority}`}>
            {currentCase.priority === 'urgent'
              ? '緊急'
              : currentCase.priority === 'high'
                ? '高'
                : '一般'}
          </span>
          <span
            className={`case-status case-status--${currentCase.status.toLowerCase()}`}
          >
            {caseStatusLabels[currentCase.status]}
          </span>
        </div>
      </header>

      <div className="comparison-layout">
        <main className="comparison-main">
          <section className="comparison-card zone-overview-card">
            <header className="simple-section-heading">
              <div>
                <p className="section-kicker">六區掃描紀錄</p>
                <h3>選擇要查看的車況影像</h3>
              </div>
              <span className="zone-count">6 / 6 已取得</span>
            </header>
            <div
              aria-label="車輛六區影像"
              className="zone-evidence-grid"
              role="tablist"
            >
              {zoneEvidence.map((zone) => (
                <button
                  aria-controls="zone-comparison-panel"
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
                <h3 id="zone-comparison-heading">
                  {activeZone.zoneLabel}・取車前／還車後比對
                </h3>
              </div>
              <span
                className={`comparability comparability--${activeZone.comparability}`}
              >
                {activeZone.comparabilityLabel}
              </span>
            </header>
            <div
              aria-labelledby="zone-comparison-heading"
              className="comparison-grid"
              id="zone-comparison-panel"
              role="tabpanel"
            >
              <EvidenceImage evidence={activeZone.baseline} />
              <EvidenceImage evidence={activeZone.current} />
            </div>
            <p className="comparison-caption">
              {activeZone.comparabilityReason}
            </p>
          </section>

          {activeZone.angles.length > 0 && (
            <section className="comparison-card">
              <header className="simple-section-heading">
                <div>
                  <p className="section-kicker">補充證據</p>
                  <h3>多角度影像</h3>
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

        <aside className="decision-summary">
          <section>
            <p className="section-kicker">判讀摘要</p>
            <h3>{finding ? findingTypeLabels[finding.type] : '未發現異常'}</h3>
            {finding ? (
              <dl className="summary-facts">
                <div>
                  <dt>位置</dt>
                  <dd>{finding.location}</dd>
                </div>
                <div>
                  <dt>嚴重程度</dt>
                  <dd>{severityLabels[finding.severity]}</dd>
                </div>
                <div>
                  <dt>是否可能新增</dt>
                  <dd>
                    {finding.possiblyNew === null
                      ? '證據不足'
                      : finding.possiblyNew
                        ? '是，待人工確認'
                        : '否'}
                  </dd>
                </div>
              </dl>
            ) : (
              <p className="muted-copy">本次掃描未建立異常紀錄。</p>
            )}
          </section>

          <section className="next-action">
            <p className="section-kicker">建議處理</p>
            <h3>{presentation.conclusion}</h3>
            <p>{currentCase.suggestedAction}</p>
          </section>

          <section className="vehicle-context">
            <dl className="summary-facts">
              <div>
                <dt>車型</dt>
                <dd>{vehicle.modelName}</dd>
              </div>
              <div>
                <dt>還車地點</dt>
                <dd>{rental.returnLocation}</dd>
              </div>
              <div>
                <dt>還車時間</dt>
                <dd>{formatFullDateTime(rental.returnAt)}</dd>
              </div>
            </dl>
          </section>

          <div className="detail-actions">
            {task && (task.type === 'cleaning' || task.type === 'repair') && (
              <Link
                className="button button--secondary"
                to={`/tasks/${task.id}`}
              >
                前往任務分配
              </Link>
            )}
            {isClaimCandidate && (
              <Link
                className="button button--primary"
                to={`/claims/${currentCase.id}`}
              >
                前往索賠審查
              </Link>
            )}
          </div>
        </aside>
      </div>
    </div>
  );
}
