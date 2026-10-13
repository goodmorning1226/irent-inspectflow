import {
  getAllRuntimeScenarioDatasets,
  getRuntimeScenarioDataset,
} from '../data/scenarios';
import { getRepairVendor } from './repairVendors';
import type {
  Assignment,
  ScenarioDataset,
  ScenarioId,
  Task,
  TaskStatus,
  TaskType,
  Worker,
} from './types';

export const taskTypeLabels: Record<TaskType, string> = {
  cleaning: '清潔',
  inspection: '保養',
  repair: '維修',
  suspension: '停用',
  claim_review: '索賠請求',
};

export const taskStatusLabels: Record<TaskStatus, string> = {
  PENDING: '待派工',
  ASSIGNED: '已指派',
  IN_PROGRESS: '處理中',
  WAITING_REVIEW: '待複檢',
  COMPLETED: '完成',
  RETURNED: '退回',
  CANCELLED: '取消',
};

export interface TaskRow {
  id: string;
  scenarioId: ScenarioId;
  caseId: string;
  title: string;
  type: TaskType;
  typeLabel: string;
  status: TaskStatus;
  statusLabel: string;
  priority: 'normal' | 'high' | 'urgent';
  plateNumber: string;
  location: string;
  deadline: string;
  reservationRisk: boolean;
  overdue: boolean;
  assignee: string;
  progressNote: string;
}

export function buildTaskRows(activeDataset: ScenarioDataset): TaskRow[] {
  return getAllRuntimeScenarioDatasets()
    .map((dataset) =>
      dataset.meta.id === activeDataset.meta.id ? activeDataset : dataset,
    )
    .flatMap((dataset) =>
      dataset.tasks.map((task) => {
        const currentCase = dataset.cases.find(
          (item) => item.id === task.caseId,
        );
        const vehicle = dataset.vehicles.find(
          (item) => item.id === currentCase?.vehicleId,
        );
        const assignment = dataset.assignments.find(
          (item) => item.taskId === task.id,
        );
        const worker = dataset.workers.find(
          (item) => item.id === assignment?.workerId,
        );
        const repairVendor = getRepairVendor(task.repairVendorId);
        return {
          id: task.id,
          scenarioId: dataset.meta.id,
          caseId: task.caseId,
          title: task.title,
          type: task.type,
          typeLabel: taskTypeLabels[task.type],
          status: task.status,
          statusLabel: taskStatusLabels[task.status],
          priority: task.priority ?? currentCase?.priority ?? 'normal',
          plateNumber: vehicle?.plateNumber ?? '—',
          location: task.location,
          deadline: task.etaLabel ?? '未設定',
          reservationRisk:
            task.reservationRisk ?? currentCase?.priority !== 'normal',
          overdue:
            dataset.meta.id === 'S03' &&
            task.type === 'claim_review' &&
            task.status !== 'COMPLETED',
          assignee:
            task.type === 'repair'
              ? (repairVendor?.name ?? '待安排送修')
              : (worker?.displayName ?? '未指派'),
          progressNote: task.progressNote ?? '處理請求已送出',
        };
      }),
    );
}

const defaultProcessingTaskIds = [
  'TSK-S01-OPS-CLEAN-001',
  'TSK-S01-OPS-CLEAN-002',
  'TSK-S01-OPS-REPAIR-001',
  'TSK-S01-OPS-REPAIR-004',
  'TSK-S01-OPS-REPAIR-006',
] as const;

const processingPriorityRank: Record<TaskRow['priority'], number> = {
  urgent: 0,
  high: 1,
  normal: 2,
};

export interface ProcessingTaskRow extends TaskRow {
  claimRequested: boolean;
}

export function selectProcessingRows(rows: TaskRow[]): ProcessingTaskRow[] {
  const activeRows = rows.filter(
    (row) =>
      row.type !== 'claim_review' &&
      row.status !== 'COMPLETED' &&
      row.status !== 'CANCELLED',
  );
  const claimCases = new Set(
    rows
      .filter(
        (row) => row.type === 'claim_review' && row.status !== 'CANCELLED',
      )
      .map((row) => row.caseId),
  );
  const createdFromRequest = activeRows.filter(
    (row) => row.progressNote === '處理請求已送出，等待外部系統回傳進度',
  );
  const defaultRows = defaultProcessingTaskIds.flatMap((taskId) => {
    const row = activeRows.find((item) => item.id === taskId);
    return row ? [row] : [];
  });
  const selectedRows = [...createdFromRequest, ...defaultRows].filter(
    (row, index, collection) =>
      collection.findIndex((item) => item.caseId === row.caseId) === index,
  );

  return selectedRows
    .sort(
      (left, right) =>
        processingPriorityRank[left.priority] -
          processingPriorityRank[right.priority] ||
        left.plateNumber.localeCompare(right.plateNumber),
    )
    .map((row) => ({
      ...row,
      claimRequested: claimCases.has(row.caseId),
    }));
}

export interface TaskWorkspace {
  dataset: ScenarioDataset;
  task: Task;
  currentCase: ScenarioDataset['cases'][number];
  vehicle: ScenarioDataset['vehicles'][number];
  finding: ScenarioDataset['findings'][number] | undefined;
  assignment: Assignment | undefined;
  worker: Worker | undefined;
}

export function buildTaskWorkspace(
  taskId: string,
  activeDataset: ScenarioDataset,
): TaskWorkspace | null {
  const scenarioId = taskId.match(/^TSK-(S0[1-7])-/)?.[1] as
    ScenarioId | undefined;
  if (!scenarioId) return null;
  const dataset =
    activeDataset.meta.id === scenarioId
      ? activeDataset
      : getRuntimeScenarioDataset(scenarioId);
  const task = dataset.tasks.find((item) => item.id === taskId);
  if (!task) return null;
  const currentCase = dataset.cases.find((item) => item.id === task.caseId);
  const vehicle = dataset.vehicles.find(
    (item) => item.id === currentCase?.vehicleId,
  );
  if (!currentCase || !vehicle) return null;
  const finding = dataset.findings.find((item) =>
    currentCase.findingIds.includes(item.id),
  );
  const assignment = dataset.assignments.find(
    (item) => item.taskId === task.id,
  );
  const worker = dataset.workers.find(
    (item) => item.id === assignment?.workerId,
  );
  return { dataset, task, currentCase, vehicle, finding, assignment, worker };
}

export interface WorkerSuggestion {
  worker: Worker;
  skillMatched: boolean;
  workload: number;
  etaLabel: string;
  reason: string;
}

export function getWorkerSuggestions(type: TaskType): WorkerSuggestion[] {
  const workers = new Map<string, Worker>();
  const assignments = new Map<string, number>();
  for (const dataset of getAllRuntimeScenarioDatasets()) {
    for (const worker of dataset.workers) workers.set(worker.id, worker);
    for (const assignment of dataset.assignments) {
      assignments.set(
        assignment.workerId,
        (assignments.get(assignment.workerId) ?? 0) + 1,
      );
    }
  }
  return [...workers.values()]
    .map((worker) => {
      const workload =
        worker.currentWorkload ?? assignments.get(worker.id) ?? 0;
      const skillMatched = worker.skills.includes(type);
      return {
        worker,
        skillMatched,
        workload,
        etaLabel:
          worker.etaLabel ??
          (workload === 0 ? '約 15 分鐘可到場' : '約 30 分鐘可到場'),
        reason: skillMatched
          ? `具備${taskTypeLabels[type]}技能，目前 ${workload} 件工作`
          : `缺少${taskTypeLabels[type]}技能，不列為優先建議`,
      };
    })
    .sort(
      (left, right) =>
        Number(right.skillMatched) - Number(left.skillMatched) ||
        left.workload - right.workload,
    );
}
