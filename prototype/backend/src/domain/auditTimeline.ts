import { getAllRuntimeScenarioDatasets } from '../data/scenarios';
import type { ScenarioDataset } from './types';

export interface AuditTimelineItem {
  id: string;
  occurredAt: string;
  category: 'model' | 'human' | 'vehicle' | 'task' | 'claim';
  title: string;
  detail: string;
  actor: string;
}

const actionLabels: Record<string, string> = {
  CLAIM_CANDIDATE_CREATED: '系統建立索賠候選',
  MANUAL_REVIEW_SUBMITTED: '人工完成車況覆核',
  FINDING_CORRECTED: '人工修正異常內容',
  CASE_STATUS_UPDATED: '案件狀態更新',
  VEHICLE_STATUS_UPDATED: '車輛狀態更新',
  TASK_CREATED: '建立處理任務',
  TASK_ASSIGNED: '任務完成指派',
  TASK_REASSIGNED: '人工改派任務',
  REPAIR_VENDOR_ASSIGNED: '確認合作維修廠',
  REPAIR_VENDOR_CHANGED: '變更合作維修廠',
  TASK_STATUS_UPDATED: '任務進度更新',
  COMPLETION_REVIEW_PASSED: '完工複檢通過',
  COMPLETION_REVIEW_RETURNED: '完工複檢退回',
  FOLLOW_UP_INSPECTION_CREATED: '建立清潔後複檢',
  VEHICLE_RELEASE_AUTHORIZED: '人工授權重新上線',
  CLAIM_DECISION_SUBMITTED: '人工送出索賠結論',
};

function categoryFor(entityType: string): AuditTimelineItem['category'] {
  if (entityType === 'vehicle') return 'vehicle';
  if (entityType === 'task') return 'task';
  if (entityType === 'claim') return 'claim';
  return 'human';
}

export function buildAuditTimeline(
  dataset: ScenarioDataset,
): AuditTimelineItem[] {
  const inspectionItems = dataset.inspectionSessions.map((session) => ({
    id: `model-${session.id}`,
    occurredAt: session.capturedAt,
    category: 'model' as const,
    title: '系統完成影像分析摘要',
    detail:
      dataset.findings.length > 0
        ? `產生 ${dataset.findings.length} 筆異常結果；結論仍需依證據狀態人工確認。`
        : '未發現需要立即處理的異常。',
    actor: 'SYSTEM-PROTOTYPE',
  }));
  const assignmentItems = dataset.assignments
    .filter((assignment) => {
      const task = dataset.tasks.find((item) => item.id === assignment.taskId);
      return task?.type !== 'repair';
    })
    .map((assignment) => ({
      id: `assignment-${assignment.id}`,
      occurredAt: assignment.assignedAt,
      category: 'task' as const,
      title: '任務完成指派',
      detail: `${assignment.taskId} 指派給 ${assignment.workerId}`,
      actor: assignment.assignedBy,
    }));
  const events = dataset.auditEvents.map((event) => ({
    id: event.id,
    occurredAt: event.occurredAt,
    category: categoryFor(event.entityType),
    title: actionLabels[event.action] ?? event.action,
    detail: event.detail,
    actor: event.actorId,
  }));
  return [...inspectionItems, ...assignmentItems, ...events].sort(
    (left, right) =>
      new Date(left.occurredAt).getTime() -
      new Date(right.occurredAt).getTime(),
  );
}

export interface ManagementMetric {
  label: string;
  value: string;
  context: string;
  tone: 'neutral' | 'warning' | 'success';
}

export function buildManagementMetrics(
  activeDataset: ScenarioDataset,
): ManagementMetric[] {
  const datasets = getAllRuntimeScenarioDatasets().map((dataset) =>
    dataset.meta.id === activeDataset.meta.id ? activeDataset : dataset,
  );
  const sessions = datasets.flatMap((dataset) => dataset.inspectionSessions);
  const captures = sessions.flatMap((session) => session.zoneCaptures);
  const qualityPassed = captures.filter((capture) =>
    /合格|已擷取|可判讀/.test(capture.qualitySummary),
  ).length;
  const cases = datasets.flatMap((dataset) => dataset.cases);
  const tasks = datasets.flatMap((dataset) => dataset.tasks);
  const decisions = datasets.flatMap((dataset) => dataset.claimDecisions);
  const closedTasks = tasks.filter(
    (task) => task.status === 'COMPLETED',
  ).length;
  const waitingCases = cases.filter((item) =>
    ['PENDING_REVIEW', 'CLAIM_REVIEW'].includes(item.status),
  ).length;
  return [
    {
      label: '拍攝品質可用',
      value: captures.length ? `${qualityPassed}／${captures.length}` : '—',
      context: '依七組固定案例的 qualitySummary 彙整',
      tone: 'success',
    },
    {
      label: '待人工覆核案件',
      value: String(waitingCases),
      context: '包含一般車況與索賠候選',
      tone: waitingCases > 0 ? 'warning' : 'success',
    },
    {
      label: '任務完成狀態',
      value: `${closedTasks}／${tasks.length}`,
      context: '不代表正式 SLA 或人員績效',
      tone: 'neutral',
    },
    {
      label: '人工索賠結論',
      value: String(decisions.length),
      context: '只計本機展示中已儲存的人工結論',
      tone: 'neutral',
    },
  ];
}
