import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import {
  buildCaseWorkspace,
  findingTypeLabels,
  formatFullDateTime,
  severityLabels,
} from '../domain/caseEvidence';
import type { ClaimOutcome } from '../domain/types';
import { useInspectFlowStore } from '../store/inspectFlowStore';

const choices: Array<{
  value: ClaimOutcome;
  label: string;
  description: string;
}> = [
  {
    value: 'EVIDENCE_SUFFICIENT',
    label: '確認進入索賠',
    description: '證據足以交由後續索賠流程處理。',
  },
  {
    value: 'REQUEST_MORE_EVIDENCE',
    label: '暫緩並補充證據',
    description: '先補齊歷史紀錄或同區域影像。',
  },
  {
    value: 'NOT_NEW_DAMAGE',
    label: '不進入索賠',
    description: '人工確認不是本次新增損傷。',
  },
];

export function ClaimDetailPage() {
  const { caseId = '' } = useParams();
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const submitClaimDecision = useInspectFlowStore(
    (state) => state.submitClaimDecision,
  );
  const workspace = useMemo(
    () => buildCaseWorkspace(caseId, dataset),
    [caseId, dataset],
  );
  const [outcome, setOutcome] = useState<ClaimOutcome | ''>('');
  const [reason, setReason] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (workspace && dataset.meta.id !== workspace.dataset.meta.id) {
      loadScenario(workspace.dataset.meta.id);
    }
  }, [dataset.meta.id, loadScenario, workspace]);

  if (!workspace) {
    return (
      <div className="empty-state">
        <span className="empty-state__stage">找不到索賠候選</span>
        <h2>{caseId}</h2>
        <Link className="button button--primary" to="/claims">
          返回索賠清單
        </Link>
      </div>
    );
  }

  const { currentCase, vehicle, rental, findings, presentation } = workspace;
  const finding = findings[0];
  const latestDecision = [...workspace.dataset.claimDecisions]
    .reverse()
    .find((item) => item.caseId === currentCase.id);

  return (
    <div className="page-stack simplified-detail">
      <header className="case-workspace-header">
        <div>
          <Link className="back-link" to="/claims">
            ← 返回索賠清單
          </Link>
          <p>
            {vehicle.plateNumber}・{currentCase.id}
          </p>
          <h2>{currentCase.title}</h2>
        </div>
        {finding && (
          <span className={`severity-pill severity-pill--${finding.severity}`}>
            {severityLabels[finding.severity]}
          </span>
        )}
      </header>

      <div className="claim-review-layout">
        <main className="claim-proof">
          <section className="comparison-card">
            <header className="simple-section-heading">
              <div>
                <p className="section-kicker">核心證據</p>
                <h3>取車前／還車後</h3>
              </div>
              <span
                className={`comparability comparability--${presentation.comparability}`}
              >
                {presentation.comparabilityLabel}
              </span>
            </header>
            <div className="comparison-grid">
              <EvidenceImage evidence={presentation.baseline} />
              <EvidenceImage evidence={presentation.current} />
            </div>
          </section>

          {presentation.angles.length > 0 && (
            <section className="comparison-card">
              <header className="simple-section-heading">
                <div>
                  <p className="section-kicker">補掃影像</p>
                  <h3>不同角度是否持續出現</h3>
                </div>
              </header>
              <div className="evidence-strip">
                {presentation.angles.map((evidence) => (
                  <EvidenceImage evidence={evidence} key={evidence.id} />
                ))}
              </div>
            </section>
          )}
        </main>

        <aside className="claim-confirmation">
          <section>
            <p className="section-kicker">案件摘要</p>
            <h3>{finding ? findingTypeLabels[finding.type] : '待確認'}</h3>
            <dl className="summary-facts">
              <div>
                <dt>位置</dt>
                <dd>{finding?.location ?? '—'}</dd>
              </div>
              <div>
                <dt>取／還車時間</dt>
                <dd>
                  {formatFullDateTime(rental.pickupAt)}
                  <br />
                  {formatFullDateTime(rental.returnAt)}
                </dd>
              </div>
              <div>
                <dt>系統判讀</dt>
                <dd>{presentation.conclusion}</dd>
              </div>
            </dl>
          </section>

          {latestDecision ? (
            <div className="saved-decision">
              <strong>已完成人工審查</strong>
              <p>{latestDecision.reason}</p>
            </div>
          ) : (
            <>
              <fieldset className="claim-choice-list">
                <legend>是否進入索賠？</legend>
                {choices.map((choice) => (
                  <label key={choice.value}>
                    <input
                      checked={outcome === choice.value}
                      name="claim-outcome"
                      onChange={() => setOutcome(choice.value)}
                      type="radio"
                    />
                    <span>
                      <strong>{choice.label}</strong>
                      <small>{choice.description}</small>
                    </span>
                  </label>
                ))}
              </fieldset>
              <label className="simple-field">
                <span>判斷理由</span>
                <textarea
                  onChange={(event) => setReason(event.target.value)}
                  placeholder="簡要說明採用哪些影像與紀錄做判斷"
                  rows={4}
                  value={reason}
                />
              </label>
              <button
                className="button button--primary"
                disabled={dataset.meta.id !== workspace.dataset.meta.id}
                onClick={() => {
                  const result = submitClaimDecision({
                    caseId: currentCase.id,
                    outcome,
                    reason,
                    note: '',
                    reviewerId: 'USR-OPS-001',
                    actorRole: 'claimReviewer',
                  });
                  setMessage(result.message);
                }}
                type="button"
              >
                儲存審查結果
              </button>
              {message && <p className="action-message">{message}</p>}
            </>
          )}
          <p className="claim-boundary-note">
            Prototype 僅展示人工審查流程；不自動歸責，也不計算賠償金額。
          </p>
        </aside>
      </div>
    </div>
  );
}
