import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { AppIcon } from '../components/AppIcon';
import { buildTaskRows, selectProcessingRows } from '../domain/taskRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

const priorityLabels = {
  urgent: '急迫',
  high: '常件',
  normal: '緩件',
} as const;

export function TasksPage() {
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const requestClaim = useInspectFlowStore((state) => state.requestClaim);
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [message, setMessage] = useState('');

  const rows = useMemo(() => {
    return selectProcessingRows(buildTaskRows(dataset));
  }, [dataset]);

  const visibleRows = rows.filter((row) =>
    `${row.plateNumber} ${row.title} ${row.location}`
      .toLocaleLowerCase('zh-TW')
      .includes(search.trim().toLocaleLowerCase('zh-TW')),
  );

  return (
    <div className="page-stack simplified-page">
      <section className="page-intro page-intro--compact">
        <h2>處理中案件</h2>
        <div className="page-list-tools">
          <label className="compact-search">
            <span>搜尋車號、處理方式或地點</span>
            <input
              onChange={(event) => setSearch(event.target.value)}
              placeholder="例如：RDF-5092、清潔"
              type="search"
              value={search}
            />
          </label>
          <button
            aria-label="篩選處理中案件"
            className="filter-icon-button"
            title="篩選"
            type="button"
          >
            <AppIcon name="filter" />
          </button>
        </div>
      </section>

      {message && (
        <p className="action-message page-action-message">{message}</p>
      )}

      <section className="simple-table-wrap" aria-label="處理中案件清單">
        <table className="simple-table unified-record-table processing-table">
          <thead>
            <tr>
              <th>車輛</th>
              <th>處理事件</th>
              <th>處理方式</th>
              <th>位置</th>
              <th>急迫性</th>
              <th>索賠請求</th>
            </tr>
          </thead>
          <tbody>
            {visibleRows.map((row) => (
              <tr
                aria-label={`查看 ${row.plateNumber} ${row.title}`}
                className="record-row"
                key={row.id}
                onClick={() => navigate(`/processing/${row.id}`)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    navigate(`/processing/${row.id}`);
                  }
                }}
                tabIndex={0}
              >
                <td>
                  <strong>{row.plateNumber}</strong>
                  <small>{row.caseId}</small>
                </td>
                <td>
                  <strong>{row.title}</strong>
                  <small>{row.id}</small>
                </td>
                <td>{row.typeLabel}</td>
                <td>{row.location}</td>
                <td>
                  <span className={`risk-label risk-label--${row.priority}`}>
                    {priorityLabels[row.priority]}
                  </span>
                </td>
                <td>
                  <button
                    className={`claim-request-button${
                      row.claimRequested ? ' is-sent' : ''
                    }`}
                    aria-disabled={row.claimRequested}
                    onClick={(event) => {
                      event.stopPropagation();
                      if (row.claimRequested) return;
                      if (row.scenarioId !== dataset.meta.id) {
                        loadScenario(row.scenarioId);
                      }
                      const result = requestClaim(row.caseId);
                      setMessage(result.message);
                    }}
                    onKeyDown={(event) => event.stopPropagation()}
                    type="button"
                  >
                    {row.claimRequested ? '已送出索賠請求' : '送出索賠請求'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {visibleRows.length === 0 && (
          <div className="simple-empty">目前沒有符合條件的處理中案件。</div>
        )}
      </section>
    </div>
  );
}
