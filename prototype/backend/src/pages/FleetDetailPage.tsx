import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import { buildCaseWorkspace, formatFullDateTime } from '../domain/caseEvidence';
import { buildFleetWorkspace } from '../domain/fleetRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function FleetDetailPage() {
  const { vehicleId = '' } = useParams();
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const workspace = useMemo(
    () => buildFleetWorkspace(vehicleId, dataset),
    [dataset, vehicleId],
  );
  const caseWorkspace = useMemo(
    () =>
      workspace
        ? buildCaseWorkspace(workspace.currentCase.id, workspace.dataset)
        : null,
    [workspace],
  );
  const [activeZoneId, setActiveZoneId] = useState('front');

  useEffect(() => {
    if (workspace && dataset.meta.id !== workspace.dataset.meta.id) {
      loadScenario(workspace.dataset.meta.id);
    }
  }, [dataset.meta.id, loadScenario, workspace]);

  useEffect(() => {
    if (caseWorkspace) setActiveZoneId(caseWorkspace.defaultZoneId);
  }, [caseWorkspace?.defaultZoneId, vehicleId]);

  if (!workspace || !caseWorkspace) {
    return (
      <div className="empty-state">
        <span className="empty-state__stage">找不到車輛紀錄</span>
        <h2>{vehicleId}</h2>
        <Link className="button button--primary" to="/fleet">
          返回車輛管理
        </Link>
      </div>
    );
  }

  const { vehicle, rental, currentCase } = workspace;
  const activeZone =
    caseWorkspace.zoneEvidence.find((zone) => zone.zoneId === activeZoneId) ??
    caseWorkspace.zoneEvidence[0];

  return (
    <div className="page-stack simplified-detail">
      <header className="case-workspace-header">
        <div>
          <Link className="back-link" to="/fleet">
            ← 返回車輛管理
          </Link>
          <p>{currentCase.id}</p>
          <h2>{vehicle.plateNumber}</h2>
        </div>
        <span
          className={`fleet-table-state fleet-table-state--${
            vehicle.availability === 'READY' ? 'ready' : 'rented'
          }`}
        >
          {vehicle.availability === 'READY' ? '待租' : '租借中'}
        </span>
      </header>

      <div className="processing-detail-layout fleet-detail-layout">
        <main className="comparison-main">
          <section className="comparison-card zone-overview-card">
            <header className="simple-section-heading">
              <div>
                <p className="section-kicker">最近一次六區車況</p>
                <h3>選擇比對區域</h3>
              </div>
              <span className="zone-count">6 / 6 已取得</span>
            </header>
            <div
              aria-label="車輛六區影像"
              className="zone-evidence-grid"
              role="tablist"
            >
              {caseWorkspace.zoneEvidence.map((zone) => (
                <button
                  aria-controls="fleet-zone-comparison"
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
                        alt={`${zone.zoneLabel}最近車況影像`}
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
                <p className="section-kicker">上次車況紀錄</p>
                <h3>{activeZone.zoneLabel}・車況比對圖</h3>
              </div>
            </header>
            <div
              className="comparison-grid"
              id="fleet-zone-comparison"
              role="tabpanel"
            >
              <EvidenceImage evidence={activeZone.baseline} />
              <EvidenceImage evidence={activeZone.current} />
            </div>
          </section>
        </main>

        <aside className="processing-request-summary">
          <p className="section-kicker">車輛資訊</p>
          <h3>{vehicle.modelName}</h3>
          <dl>
            <div>
              <dt>車號</dt>
              <dd>{vehicle.plateNumber}</dd>
            </div>
            <div>
              <dt>車色</dt>
              <dd>{vehicle.colorName}</dd>
            </div>
            <div>
              <dt>目前狀態</dt>
              <dd>{vehicle.availability === 'READY' ? '待租' : '租借中'}</dd>
            </div>
            <div>
              <dt>目前位置</dt>
              <dd>{rental.returnLocation}</dd>
            </div>
            <div>
              <dt>最後更新</dt>
              <dd>{formatFullDateTime(currentCase.updatedAt)}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </div>
  );
}
