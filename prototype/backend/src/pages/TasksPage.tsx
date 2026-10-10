import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { buildTaskRows } from '../domain/taskRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function TasksPage() {
  const dataset = useInspectFlowStore((state) => state.dataset);
  const navigate = useNavigate();
  const [type, setType] = useState<'all' | 'cleaning' | 'repair'>('all');
  const rows = useMemo(
    () =>
      buildTaskRows(dataset).filter(
        (row) => row.type === 'cleaning' || row.type === 'repair',
      ),
    [dataset],
  );
  const visibleRows = rows.filter((row) => type === 'all' || row.type === type);

  return (
    <div className="page-stack simplified-page">
      <section className="page-intro">
        <div>
          <p className="section-kicker">任務分配</p>
          <h2>把異常直接交給合適的清潔或維修人員</h2>
          <p>
            營運人員只需確認任務類型、地點與期限，再選擇執行人員。此 Prototype
            暫不製作員工接單與完工回報介面。
          </p>
        </div>
        <div className="segmented-filter" aria-label="任務類型">
          {[
            ['all', '全部'],
            ['cleaning', '清潔'],
            ['repair', '維修'],
          ].map(([value, label]) => (
            <button
              className={type === value ? 'is-active' : ''}
              key={value}
              onClick={() => setType(value as typeof type)}
              type="button"
            >
              {label}
            </button>
          ))}
        </div>
      </section>

      <section className="task-board" aria-label="清潔與維修任務">
        {visibleRows.map((row) => (
          <article className="assignment-card" key={row.id}>
            <div
              className={`assignment-card__type assignment-card__type--${row.type}`}
            >
              {row.typeLabel}
            </div>
            <div className="assignment-card__body">
              <div>
                <strong>{row.title}</strong>
                <small>
                  {row.plateNumber}・{row.location}
                </small>
              </div>
              <dl>
                <div>
                  <dt>期限</dt>
                  <dd>{row.deadline}</dd>
                </div>
                <div>
                  <dt>目前負責人</dt>
                  <dd>{row.assignee}</dd>
                </div>
              </dl>
            </div>
            <button
              className="table-action"
              onClick={() => navigate(`/tasks/${row.id}`)}
              type="button"
            >
              分配人員
            </button>
          </article>
        ))}
      </section>
    </div>
  );
}
