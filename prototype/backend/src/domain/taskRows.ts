import { getAllScenarioDatasets, getScenarioDataset } from '../data/scenarios';
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
  inspection: '巡檢',
  repair: '維修',
  claim_review: '索賠待審',
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
}

export function buildTaskRows(activeDataset: ScenarioDataset): TaskRow[] {
  return getAllScenarioDatasets()
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
          assignee: worker?.displayName ?? '未指派',
        };
      }),
    );
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
      : getScenarioDataset(scenarioId);
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
  for (const dataset of getAllScenarioDatasets()) {
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
