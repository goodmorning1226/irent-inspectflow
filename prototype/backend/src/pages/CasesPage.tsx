import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { buildCaseRows, formatCaseTime } from '../domain/caseRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

const riskLabels = { urgent: '緊急', high: '高', normal: '一般' } as const;

export function CasesPage() {
  const dataset = useInspectFlowStore((state) => state.dataset);
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const rows = useMemo(() => buildCaseRows(dataset), [dataset]);
  const visibleRows = rows.filter((row) =>
    `${row.plateNumber} ${row.title} ${row.anomalyLabel}`
      .toLocaleLowerCase('zh-TW')
      .includes(search.trim().toLocaleLowerCase('zh-TW')),
  );

  return (
    <div className="page-stack simplified-page">
      <section className="page-intro">
        <div>
          <p className="section-kicker">車況比對</p>
          <h2>先看前後差異，再決定後續處理</h2>
          <p>
            每筆車況集中呈現同一車輛、同一區域的取車前與還車後影像。點選車輛即可查看差異、異常位置與建議處理方向。
          </p>
        </div>
        <label className="compact-search">
          <span>搜尋車號或異常</span>
          <input
            onChange={(event) => setSearch(event.target.value)}
            placeholder="例如：ABC-1234、刮痕"
            type="search"
            value={search}
          />
        </label>
      </section>

      <section className="simple-table-wrap" aria-label="車況比對清單">
        <table className="simple-table">
          <thead>
            <tr>
              <th>車輛</th>
              <th>偵測結果</th>
              <th>嚴重程度</th>
              <th>目前狀態</th>
              <th>掃描時間</th>
              <th aria-label="操作" />
            </tr>
          </thead>
          <tbody>
            {visibleRows.map((row) => (
              <tr key={row.id}>
                <td>
                  <strong>{row.plateNumber}</strong>
                  <small>{row.id}</small>
                </td>
                <td>
                  <strong>{row.anomalyLabel}</strong>
                  <small>{row.title}</small>
                </td>
                <td>
                  <span className={`risk-label risk-label--${row.risk}`}>
                    {riskLabels[row.risk]}
                  </span>
                </td>
                <td>
                  <span
                    className={`case-status case-status--${row.status.toLowerCase()}`}
                  >
                    {row.statusLabel}
                  </span>
                </td>
                <td>{formatCaseTime(row.createdAt)}</td>
                <td>
                  <button
                    className="table-action"
                    onClick={() => navigate(`/cases/${row.id}`)}
                    type="button"
                  >
                    查看比對
                  </button>
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
