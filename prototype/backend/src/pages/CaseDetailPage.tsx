import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import {
  ProcessingRequestDialog,
  type ProcessingMethod,
} from '../components/ProcessingRequestDialog';
import {
  buildCaseWorkspace,
  formatFindingType,
  formatFullDateTime,
  severityLabels,
} from '../domain/caseEvidence';
import { caseStatusLabels } from '../domain/caseRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function CaseDetailPage() {
  const { caseId = '' } = useParams();
  const activeDataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const submitReview = useInspectFlowStore((state) => state.submitReview);
  const createTask = useInspectFlowStore((state) => state.createTask);
  const requestClaim = useInspectFlowStore((state) => state.requestClaim);
  const updateCaseStatus = useInspectFlowStore(
    (state) => state.updateCaseStatus,
  );
  const navigate = useNavigate();
  const workspace = useMemo(
    () => buildCaseWorkspace(caseId, activeDataset),
    [activeDataset, caseId],
  );
  const [activeZoneId, setActiveZoneId] = useState('front');
  const [baselineSource, setBaselineSource] = useState<
    'pickup' | 'previousReturn'
  >('pickup');
  const [dialogMode, setDialogMode] = useState<'processing' | 'claim' | null>(
    null,
  );
  const [reviewMessage, setReviewMessage] = useState('');

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

  const { currentCase, vehicle, rental, findings, presentation, zoneEvidence } =
    workspace;
  const activeZone =
    zoneEvidence.find((zone) => zone.zoneId === activeZoneId) ??
    zoneEvidence[0];
  const comparisonBaseline = {
    ...activeZone.baseline,
    id: `${activeZone.baseline.id}-${baselineSource}`,
    label: baselineSource === 'pickup' ? '本次取車前' : '上次還車',
    caption:
      baselineSource === 'pickup'
        ? `${activeZone.zoneLabel}在本次租程取車前的掃描影像`
        : `${activeZone.zoneLabel}在上一筆租程還車後的有效影像`,
    sourceLabel:
      baselineSource === 'pickup'
        ? '本次租程・取車前掃描'
        : '前次租程・還車影像',
  };
  const finding = findings[0];
  function submitProcessing(method: ProcessingMethod) {
    const includeClaim = dialogMode === 'claim';
    const vehicleStatus =
      method === 'cleaning'
        ? 'CLEANING'
        : method === 'suspension'
          ? 'OFFLINE'
          : 'MAINTENANCE';
    const review = submitReview({
      caseId: currentCase.id,
      findingId: finding?.id ?? null,
      outcome: 'CONFIRMED_ANOMALY',
      correctedType: finding?.type ?? 'unknown',
      correctedSeverity: finding?.severity ?? 'medium',
      vehicleStatus,
      reason: `人工確認異常，透過 API 送出${
        method === 'cleaning' ? '清潔' : method === 'repair' ? '維修' : '停用'
      }處理請求。`,
      note: includeClaim ? '同步送出索賠請求。' : '',
      reviewerId: 'USR-OPS-001',
    });
    if (!review.ok) {
      setReviewMessage(
        review.errors.case ??
          review.errors.reason ??
          review.errors.outcome ??
          '無法送出審核結果。',
      );
      return;
    }
    updateCaseStatus(
      currentCase.id,
      method === 'cleaning'
        ? 'PENDING_CLEANING'
        : method === 'repair'
          ? 'PENDING_REPAIR'
          : 'PENDING_INSPECTION',
    );

    const result = createTask({
      caseId: currentCase.id,
      type: method,
      title: `${vehicle.plateNumber} ${
        method === 'cleaning'
          ? '清潔處理'
          : method === 'repair'
            ? '維修處理'
            : '暫停供租'
      }`,
      actorId: 'USR-OPS-001',
      priority: currentCase.priority,
    });
    if ((result.ok || result.entityId) && result.entityId) {
      if (includeClaim) requestClaim(currentCase.id);
      setDialogMode(null);
      navigate('/cases');
      return;
    }
    setReviewMessage(result.message);
  }

  function markAsFalsePositive() {
    const review = submitReview({
      caseId: currentCase.id,
      findingId: finding?.id ?? null,
      outcome: 'NOT_DAMAGE',
      correctedType: null,
      correctedSeverity: null,
      vehicleStatus: 'READY',
      reason: '人工確認為影像誤判，車輛恢復正常狀態。',
      note: '',
      reviewerId: 'USR-OPS-001',
    });
    if (!review.ok) {
      setReviewMessage(review.errors.case ?? '無法更新案件狀態。');
      return;
    }
    navigate('/cases');
  }

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
                  {activeZone.zoneLabel}・車況差異比對
                </h3>
              </div>
              <div className="comparison-heading-actions">
                <div
                  aria-label="選擇車況比對基準"
                  className="baseline-source-switch"
                >
                  <button
                    className={baselineSource === 'pickup' ? 'is-active' : ''}
                    onClick={() => setBaselineSource('pickup')}
                    type="button"
                  >
                    本次取車前
                  </button>
                  <button
                    className={
                      baselineSource === 'previousReturn' ? 'is-active' : ''
                    }
                    onClick={() => setBaselineSource('previousReturn')}
                    type="button"
                  >
                    上次還車
                  </button>
                </div>
                <span
                  className={`comparability comparability--${activeZone.comparability}`}
                >
                  {activeZone.comparabilityLabel}
                </span>
              </div>
            </header>
            <div
              aria-labelledby="zone-comparison-heading"
              className="comparison-grid"
              id="zone-comparison-panel"
              role="tabpanel"
            >
              <EvidenceImage evidence={comparisonBaseline} />
              <EvidenceImage evidence={activeZone.current} />
            </div>
            <p className="comparison-caption">
              {baselineSource === 'pickup'
                ? '優先以本次租程的取車前掃描界定異常是否在租程中出現。'
                : '上次還車影像用來確認異常是否更早存在，也可在取車前影像不足時作為備援。'}{' '}
              {activeZone.comparabilityReason}
            </p>
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

        <aside className="decision-summary">
          <section>
            <p className="section-kicker">判讀摘要</p>
            <h3>{finding ? formatFindingType(finding) : '待確認異常'}</h3>
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

          <section className="anomaly-review-controls">
            <div className="review-recommendation">
              <p className="section-kicker">AI 建議</p>
              <h3>{presentation.conclusion}</h3>
              <p>{currentCase.suggestedAction}</p>
            </div>
            <h3>人工審核</h3>
            <div className="review-dispatch-actions">
              <button
                className="review-claim-submit"
                onClick={() => setDialogMode('claim')}
                type="button"
              >
                送出索賠評估與處理請求
              </button>
              <button
                className="review-submit"
                onClick={() => setDialogMode('processing')}
                type="button"
              >
                送出車況處理請求
              </button>
              <button
                className="review-dismiss"
                onClick={markAsFalsePositive}
                type="button"
              >
                確認無異常並恢復服務
              </button>
            </div>
            {reviewMessage && <p className="action-message">{reviewMessage}</p>}
          </section>
        </aside>
      </div>
      <ProcessingRequestDialog
        includeClaim={dialogMode === 'claim'}
        onClose={() => setDialogMode(null)}
        onConfirm={submitProcessing}
        open={dialogMode !== null}
        plateNumber={vehicle.plateNumber}
      />
    </div>
  );
}
