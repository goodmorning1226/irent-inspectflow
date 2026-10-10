import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';

import { buildClaimRows } from '../domain/claimRows';
import { formatCaseTime } from '../domain/caseRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function ClaimsPage() {
  const dataset = useInspectFlowStore((state) => state.dataset);
  const navigate = useNavigate();
  const rows = useMemo(() => buildClaimRows(dataset), [dataset]);

  return (
    <div className="page-stack simplified-page">
      <section className="page-intro">
        <div>
          <p className="section-kicker">索賠審查</p>
          <h2>先處理嚴重案件，再由人員確認是否進入索賠</h2>
          <p>
            清單只收錄「疑似本次新增」的車身損傷，並依嚴重程度由高至低排列。AI
            只整理證據，不自動認定責任或賠償金額。
          </p>
        </div>
        <div className="queue-result">
          <strong>{rows.length}</strong>
          <span> 筆待審候選</span>
        </div>
      </section>

      <section className="claim-list" aria-label="索賠候選清單">
        {rows.map((row, index) => (
          <button
            className="claim-list-row"
            key={row.caseId}
            onClick={() => navigate(`/claims/${row.caseId}`)}
            type="button"
          >
            <span className="claim-rank">
              {String(index + 1).padStart(2, '0')}
            </span>
            <span className="claim-list-row__vehicle">
              <strong>{row.plateNumber}</strong>
              <small>{row.caseId}</small>
            </span>
            <span>
              <strong>{row.typeLabel}</strong>
              <small>{row.location}</small>
            </span>
            <span className={`severity-pill severity-pill--${row.severity}`}>
              {row.severityLabel}
            </span>
            <span>
              <small>建立時間</small>
              <strong>{formatCaseTime(row.createdAt)}</strong>
            </span>
            <span
              className={row.reviewed ? 'review-state is-done' : 'review-state'}
            >
              {row.reviewed ? '已審查' : '待確認'}
            </span>
            <span className="claim-list-row__action">查看證據 →</span>
          </button>
        ))}
      </section>
    </div>
  );
}
