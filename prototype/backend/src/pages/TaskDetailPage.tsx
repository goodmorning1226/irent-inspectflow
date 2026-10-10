import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { EvidenceImage } from '../components/EvidenceImage';
import type { EvidenceImage as EvidenceImageData } from '../domain/caseEvidence';
import {
  buildTaskWorkspace,
  getWorkerSuggestions,
  taskStatusLabels,
  taskTypeLabels,
} from '../domain/taskRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function TaskDetailPage() {
  const { taskId = '' } = useParams();
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const assignTask = useInspectFlowStore((state) => state.assignTask);
  const workspace = useMemo(
    () => buildTaskWorkspace(taskId, dataset),
    [dataset, taskId],
  );
  const [selectedWorkerId, setSelectedWorkerId] = useState('');
  const [reason, setReason] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (workspace && dataset.meta.id !== workspace.dataset.meta.id) {
      loadScenario(workspace.dataset.meta.id);
    }
  }, [dataset.meta.id, loadScenario, workspace]);

  useEffect(() => {
    setSelectedWorkerId(workspace?.assignment?.workerId ?? '');
    setReason('');
    setMessage('');
  }, [taskId, workspace?.assignment?.workerId]);

  if (!workspace) {
    return (
      <div className="empty-state">
        <span className="empty-state__stage">找不到任務</span>
        <h2>{taskId}</h2>
        <Link className="button button--primary" to="/tasks">
          返回任務分配
        </Link>
      </div>
    );
  }

  const { task, currentCase, vehicle, finding, assignment, worker } = workspace;
  const suggestions = getWorkerSuggestions(task.type).filter(
    (item) => item.skillMatched,
  );
  const evidence: EvidenceImageData = {
    id: 'task-evidence',
    label: '異常影像',
    caption: finding?.location ?? currentCase.title,
    src:
      task.type === 'cleaning'
        ? '/interior_dirty_best.png'
        : finding?.location.includes('車燈')
          ? '/headlight_damage_detail.png'
          : '/exterior_damage_wide.png',
    effect: 'none',
    sourceLabel: `${currentCase.id}・Prototype`,
  };
  const isReassignment = Boolean(
    assignment && selectedWorkerId !== assignment.workerId,
  );

  return (
    <div className="page-stack simplified-detail">
      <header className="case-workspace-header">
        <div>
          <Link className="back-link" to="/tasks">
            ← 返回任務分配
          </Link>
          <p>
            {task.id}・{vehicle.plateNumber}
          </p>
          <h2>{task.title}</h2>
        </div>
        <span
          className={`task-status task-status--${task.status.toLowerCase()}`}
        >
          {taskStatusLabels[task.status]}
        </span>
      </header>

      <div className="assignment-layout">
        <section className="assignment-evidence">
          <EvidenceImage evidence={evidence} />
          <dl className="summary-facts assignment-facts">
            <div>
              <dt>任務類型</dt>
              <dd>{taskTypeLabels[task.type]}</dd>
            </div>
            <div>
              <dt>異常位置</dt>
              <dd>{finding?.location ?? '依任務內容確認'}</dd>
            </div>
            <div>
              <dt>地點</dt>
              <dd>{task.location}</dd>
            </div>
            <div>
              <dt>完成期限</dt>
              <dd>{task.etaLabel ?? '未設定'}</dd>
            </div>
          </dl>
        </section>

        <section className="worker-picker">
          <header>
            <p className="section-kicker">選擇執行人員</p>
            <h3>{task.type === 'cleaning' ? '清潔人員' : '維修人員'}</h3>
          </header>
          <div className="worker-list">
            {suggestions.map((item) => (
              <label key={item.worker.id}>
                <input
                  checked={selectedWorkerId === item.worker.id}
                  name="worker"
                  onChange={() => setSelectedWorkerId(item.worker.id)}
                  type="radio"
                />
                <span>
                  <strong>{item.worker.displayName}</strong>
                  <small>
                    {item.worker.team}・{item.etaLabel}
                  </small>
                </span>
                {item.worker.id === assignment?.workerId && <em>目前</em>}
              </label>
            ))}
          </div>
          {isReassignment && (
            <label className="simple-field">
              <span>改派理由</span>
              <textarea
                onChange={(event) => setReason(event.target.value)}
                placeholder="例如：距離較近，可更快到場"
                rows={3}
                value={reason}
              />
            </label>
          )}
          <button
            className="button button--primary"
            disabled={
              !selectedWorkerId || selectedWorkerId === assignment?.workerId
            }
            onClick={() => {
              const result = assignTask(
                task.id,
                selectedWorkerId,
                reason,
                'USR-OPS-001',
              );
              setMessage(result.message);
            }}
            type="button"
          >
            確認分配
          </button>
          {worker && (
            <p className="current-assignee">目前負責人：{worker.displayName}</p>
          )}
          {message && <p className="action-message">{message}</p>}
        </section>
      </div>
    </div>
  );
}
