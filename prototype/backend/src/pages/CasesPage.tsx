import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { AppIcon } from '../components/AppIcon';
import { buildCaseRows, formatCaseTime } from '../domain/caseRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

const riskLabels = { urgent: '緊急', high: '高', normal: '一般' } as const;
const riskRank = { urgent: 0, high: 1, normal: 2 } as const;
const reviewableTypes = new Set([
  'scratch',
  'dent',
  'crack',
  'stain',
  'litter',
  'leftItem',
  'obstruction',
  'unknown',
]);

const classificationLabels = {
  scratch: '疑似新車損',
  dent: '疑似新車損',
  crack: '疑似新車損',
  stain: '髒污',
  litter: '髒污',
  leftItem: '髒污',
  obstruction: '髒污',
  unknown: '待確認',
} as const;

function getClassificationLabel(
  anomalyType: keyof typeof classificationLabels,
  anomalyZone: string | null,
) {
  if (['stain', 'litter', 'leftItem', 'obstruction'].includes(anomalyType)) {
    return ['frontSeat', 'rearSeat'].includes(anomalyZone ?? '')
      ? '車內髒污'
      : '車外髒污';
  }
  return classificationLabels[anomalyType];
}

export function CasesPage() {
  const dataset = useInspectFlowStore((state) => state.dataset);
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const rows = useMemo(
    () =>
      buildCaseRows(dataset).filter(
        (row) =>
          reviewableTypes.has(row.anomalyType) &&
          row.status === 'PENDING_REVIEW' &&
          !row.hasActiveTask &&
          !row.inClaimQueue,
      ),
    [dataset],
  );
  const visibleRows = rows
    .filter((row) =>
      `${row.plateNumber} ${row.title} ${row.anomalyLabel}`
        .toLocaleLowerCase('zh-TW')
        .includes(search.trim().toLocaleLowerCase('zh-TW')),
    )
    .sort(
      (left, right) =>
        riskRank[left.risk] - riskRank[right.risk] ||
        Date.parse(right.createdAt) - Date.parse(left.createdAt),
    );

  return (
    <div className="page-stack simplified-page">
      <section className="page-intro">
        <h2>待審異常案件</h2>
        <div className="page-list-tools">
          <label className="compact-search">
            <span>搜尋車號或異常</span>
            <input
              onChange={(event) => setSearch(event.target.value)}
              placeholder="例如：ABC-1234、刮痕"
              type="search"
              value={search}
            />
          </label>
          <button
            aria-label="篩選案件"
            className="filter-icon-button"
            title="篩選"
            type="button"
          >
            <AppIcon name="filter" />
          </button>
        </div>
      </section>

      <section className="simple-table-wrap" aria-label="車況比對清單">
        <table className="simple-table unified-record-table">
          <thead>
            <tr>
              <th>車輛</th>
              <th>偵測結果</th>
              <th>異常位置</th>
              <th>AI 分類</th>
              <th>嚴重程度</th>
              <th>車輛狀態</th>
            </tr>
          </thead>
          <tbody>
            {visibleRows.map((row) => (
              <tr
                aria-label={`審核 ${row.plateNumber} ${row.anomalyLabel}`}
                className="record-row"
                key={row.id}
                onClick={() => navigate(`/cases/${row.id}`)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    navigate(`/cases/${row.id}`);
                  }
                }}
                tabIndex={0}
              >
                <td>
                  <strong>{row.plateNumber}</strong>
                  <small>{row.id}</small>
                </td>
                <td>
                  <strong>{row.anomalyLabel}</strong>
                  <small>{row.title}</small>
                </td>
                <td>{row.location}</td>
                <td>
                  <span
                    className={`classification classification--${row.anomalyType}`}
                  >
                    {getClassificationLabel(
                      row.anomalyType as keyof typeof classificationLabels,
                      row.anomalyZone,
                    )}
                  </span>
                </td>
                <td>
                  <span className={`risk-label risk-label--${row.risk}`}>
                    {riskLabels[row.risk]}
                  </span>
                </td>
                <td>
                  <span className="dispatch-hold">已暫停供租</span>
                  <small>{formatCaseTime(row.createdAt)}</small>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {visibleRows.length === 0 && (
          <div className="simple-empty">找不到符合條件的車況紀錄。</div>
        )}
      </section>
    </div>
  );
}
