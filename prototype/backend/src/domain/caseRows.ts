import { getAllScenarioDatasets } from '../data/scenarios';
import type {
  CaseStatus,
  FindingType,
  ScenarioDataset,
  TaskStatus,
  VehicleAvailability,
} from './types';

export type CaseRisk = 'normal' | 'high' | 'urgent';
export type CaseSort = 'priority' | 'newest' | 'confidence';

export interface CaseRow {
  id: string;
  scenarioId: string;
  title: string;
  plateNumber: string;
  anomalyType: FindingType | 'none';
  anomalyLabel: string;
  risk: CaseRisk;
  confidence: number | null;
  status: CaseStatus;
  statusLabel: string;
  createdAt: string;
  deadline: string;
  assignee: string;
  location: string;
  availability: VehicleAvailability;
  taskStatus: TaskStatus | null;
  isDueSoon: boolean;
  evidenceInsufficient: boolean;
}

export interface CaseFilters {
  search: string;
  status: string;
  anomalyType: string;
  risk: string;
  location: string;
  assignee: string;
  availability: string;
  due: string;
  sort: CaseSort;
}

export const defaultCaseFilters: CaseFilters = {
  search: '',
  status: '',
  anomalyType: '',
  risk: '',
  location: '',
  assignee: '',
  availability: '',
  due: '',
  sort: 'priority',
};

const anomalyLabels: Record<FindingType | 'none', string> = {
  none: '無需處理異常',
  scratch: '刮痕',
  dent: '凹陷',
  crack: '破裂',
  stain: '污漬',
  litter: '垃圾',
  leftItem: '遺留物',
  reflection: '反光干擾',
  obstruction: '遮蔽',
  unknown: '待確認',
};

export const caseStatusLabels: Record<CaseStatus, string> = {
  RESOLVED: '已完成',
  PENDING_REVIEW: '待覆核',
  PENDING_CLEANING: '待清潔',
  PENDING_INSPECTION: '待巡檢',
  PENDING_REPAIR: '待維修',
  CLAIM_REVIEW: '索賠覆核',
};

const riskRank: Record<CaseRisk, number> = { urgent: 0, high: 1, normal: 2 };

const reviewerLabels: Record<string, string> = {
  'USR-OPS-001': '營運人員',
  'USR-DISPATCH-001': '派工人員',
  'USR-CLAIM-001': '索賠覆核人員',
};

export function buildCaseRows(activeDataset: ScenarioDataset): CaseRow[] {
  return getAllScenarioDatasets()
    .map((initialDataset) =>
      initialDataset.meta.id === activeDataset.meta.id
        ? activeDataset
        : initialDataset,
    )
    .flatMap((dataset) =>
      dataset.cases.map((currentCase) => {
        const vehicle = dataset.vehicles.find(
          (item) => item.id === currentCase.vehicleId,
        );
        const rental = dataset.rentals.find(
          (item) => item.id === currentCase.rentalId,
        );
        const finding = dataset.findings.find((item) =>
          currentCase.findingIds.includes(item.id),
        );
        const task = dataset.tasks.find(
          (item) => item.caseId === currentCase.id,
        );
        const assignment = dataset.assignments.find(
          (item) => item.taskId === task?.id,
        );
        const worker = dataset.workers.find(
          (item) => item.id === assignment?.workerId,
        );
        const anomalyType = finding?.type ?? 'none';
        return {
          id: currentCase.id,
          scenarioId: currentCase.scenarioId,
          title: currentCase.title,
          plateNumber: vehicle?.plateNumber ?? '—',
          anomalyType,
          anomalyLabel: anomalyLabels[anomalyType],
          risk: currentCase.priority,
          confidence: finding?.confidence ?? null,
          status: currentCase.status,
          statusLabel: caseStatusLabels[currentCase.status],
          createdAt: currentCase.createdAt,
          deadline: task?.etaLabel ?? '未設定',
          assignee:
            (currentCase.reviewerId &&
              reviewerLabels[currentCase.reviewerId]) ??
            worker?.displayName ??
            '未指派',
          location: rental?.returnLocation ?? '未提供',
          availability: vehicle?.availability ?? 'REVIEW_REQUIRED',
          taskStatus: task?.status ?? null,
          isDueSoon: Boolean(
            task?.etaLabel &&
            task.status !== 'COMPLETED' &&
            task.status !== 'CANCELLED',
          ),
          evidenceInsufficient: finding?.evidenceState === 'insufficient',
        };
      }),
    );
}

export function filterAndSortCaseRows(
  rows: CaseRow[],
  filters: CaseFilters,
): CaseRow[] {
  const search = filters.search.trim().toLocaleLowerCase('zh-TW');
  const filtered = rows.filter((row) => {
    if (
      search &&
      !`${row.id} ${row.plateNumber} ${row.title}`
        .toLocaleLowerCase('zh-TW')
        .includes(search)
    )
      return false;
    if (
      filters.status === 'review' &&
      row.status !== 'PENDING_REVIEW' &&
      row.status !== 'CLAIM_REVIEW'
    )
      return false;
    if (
      filters.status &&
      filters.status !== 'review' &&
      row.status !== filters.status
    )
      return false;
    if (filters.anomalyType && row.anomalyType !== filters.anomalyType)
      return false;
    if (filters.risk && row.risk !== filters.risk) return false;
    if (filters.location && row.location !== filters.location) return false;
    if (filters.assignee && row.assignee !== filters.assignee) return false;
    if (filters.availability === 'unavailable' && row.availability === 'READY')
      return false;
    if (filters.availability === 'ready' && row.availability !== 'READY')
      return false;
    if (filters.due === 'soon' && !row.isDueSoon) return false;
    return true;
  });

  return filtered.sort((left, right) => {
    if (filters.sort === 'newest') {
      return Date.parse(right.createdAt) - Date.parse(left.createdAt);
    }
    if (filters.sort === 'confidence') {
      return (right.confidence ?? -1) - (left.confidence ?? -1);
    }
    return (
      riskRank[left.risk] - riskRank[right.risk] ||
      Date.parse(right.createdAt) - Date.parse(left.createdAt)
    );
  });
}

export function formatCaseTime(value: string) {
  return new Intl.DateTimeFormat('zh-TW', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(new Date(value));
}
