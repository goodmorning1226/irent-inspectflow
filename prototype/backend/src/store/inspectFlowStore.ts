import { create } from 'zustand';

import {
  getRuntimeScenarioDataset,
  getScenarioDataset,
  isScenarioDataset,
  saveRuntimeScenarioDataset,
} from '../data/scenarios';
import type {
  AuditEvent,
  Case,
  CaseStatus,
  ClaimOutcome,
  FindingSeverity,
  FindingType,
  ReviewOutcome,
  ScenarioDataset,
  ScenarioId,
  TaskStatus,
  TaskType,
  VehicleAvailability,
} from '../domain/types';

export const STORE_VERSION = 10;
export const DEFAULT_SCENARIO_ID: ScenarioId = 'S01';

export interface ReviewSubmission {
  caseId: string;
  findingId: string | null;
  outcome: ReviewOutcome | '';
  correctedType: FindingType | null;
  correctedSeverity: FindingSeverity | null;
  vehicleStatus: VehicleAvailability;
  reason: string;
  note: string;
  reviewerId: string;
}

export interface ReviewSubmissionResult {
  ok: boolean;
  errors: Partial<Record<'outcome' | 'reason' | 'case', string>>;
}

export interface OperationResult {
  ok: boolean;
  message: string;
  entityId?: string;
}

export interface CreateTaskInput {
  caseId: string;
  type: Exclude<TaskType, 'claim_review'>;
  title: string;
  actorId: string;
  priority?: Case['priority'];
}

export interface ReleaseGate {
  tasksComplete: boolean;
  evidencePassed: boolean;
  humanAuthorized: boolean;
  canAuthorize: boolean;
  ready: boolean;
}

export interface ClaimDecisionInput {
  caseId: string;
  outcome: ClaimOutcome | '';
  reason: string;
  note: string;
  reviewerId: string;
  actorRole: string;
}

interface PersistedSlice {
  activeScenarioId: ScenarioId;
  dataset: ScenarioDataset;
}

interface InspectFlowStore extends PersistedSlice {
  loadScenario: (scenarioId: ScenarioId) => void;
  getCaseById: (caseId: string) => Case | undefined;
  updateCaseStatus: (
    caseId: string,
    status: CaseStatus,
    actorId?: string,
  ) => void;
  updateTaskStatus: (
    taskId: string,
    status: TaskStatus,
    actorId?: string,
  ) => void;
  updateVehicleStatus: (
    vehicleId: string,
    status: VehicleAvailability,
    reason: string,
    actorId?: string,
  ) => void;
  submitReview: (input: ReviewSubmission) => ReviewSubmissionResult;
  createTask: (input: CreateTaskInput) => OperationResult;
  requestClaim: (caseId: string, actorId?: string) => OperationResult;
  transitionTask: (
    taskId: string,
    nextStatus: TaskStatus,
    actorId: string,
  ) => OperationResult;
  reviewCompletion: (
    taskId: string,
    result: 'PASSED' | 'RETURNED',
    reason: string,
    actorId: string,
  ) => OperationResult;
  authorizeVehicleRelease: (
    caseId: string,
    reason: string,
    actorId: string,
  ) => OperationResult;
  submitClaimDecision: (input: ClaimDecisionInput) => OperationResult;
  resetActiveScenario: () => void;
}

export function canSubmitClaimDecision(role: string) {
  return role === 'claimReviewer';
}

export function validateClaimDecision(
  input: ClaimDecisionInput,
): OperationResult {
  if (!canSubmitClaimDecision(input.actorRole)) {
    return { ok: false, message: '目前角色只能查看證據，無權送出索賠結論。' };
  }
  if (!input.outcome) return { ok: false, message: '請選擇人工索賠結論。' };
  if (!input.reason.trim()) {
    return { ok: false, message: '人工索賠結論必須填寫判斷理由。' };
  }
  return { ok: true, message: '索賠結論資料有效。' };
}

export function evaluateReleaseGate(
  dataset: ScenarioDataset,
  caseId: string,
): ReleaseGate {
  const tasks = dataset.tasks.filter(
    (task) => task.caseId === caseId && task.status !== 'CANCELLED',
  );
  const tasksComplete =
    tasks.length > 0 && tasks.every((task) => task.status === 'COMPLETED');
  const evidencePassed =
    tasks.length > 0 &&
    tasks.every((task) => {
      const latest = [...dataset.completionReviews]
        .reverse()
        .find((review) => review.taskId === task.id);
      return latest?.result === 'PASSED' && latest.sameRegion;
    });
  const humanAuthorized = dataset.releaseAuthorizations.some(
    (authorization) => authorization.caseId === caseId,
  );
  return {
    tasksComplete,
    evidencePassed,
    humanAuthorized,
    canAuthorize: tasksComplete && evidencePassed && !humanAuthorized,
    ready: tasksComplete && evidencePassed && humanAuthorized,
  };
}

const legalTaskTransitions: Partial<Record<TaskStatus, TaskStatus[]>> = {
  ASSIGNED: ['IN_PROGRESS'],
  IN_PROGRESS: ['WAITING_REVIEW'],
  RETURNED: ['IN_PROGRESS'],
};

export function validateReviewSubmission(
  input: ReviewSubmission,
): ReviewSubmissionResult {
  const errors: ReviewSubmissionResult['errors'] = {};
  if (!input.outcome) errors.outcome = '請選擇人工覆核結果。';
  if (!input.reason.trim())
    errors.reason = '請填寫判斷理由，才能儲存人工覆核。';
  return { ok: Object.keys(errors).length === 0, errors };
}

function reviewedCaseStatus(
  outcome: ReviewOutcome,
  findingType: FindingType | undefined,
  previous: CaseStatus,
): CaseStatus {
  if (outcome === 'NOT_DAMAGE') return 'RESOLVED';
  if (
    outcome === 'EVIDENCE_INSUFFICIENT' ||
    outcome === 'REQUEST_MORE_EVIDENCE'
  )
    return 'PENDING_INSPECTION';
  if (outcome === 'RETURNED') return 'PENDING_REVIEW';
  if (previous === 'CLAIM_REVIEW') return previous;
  if (findingType === 'stain' || findingType === 'obstruction')
    return 'PENDING_CLEANING';
  if (findingType === 'crack') return 'PENDING_REPAIR';
  return 'PENDING_INSPECTION';
}

function initialSlice(scenarioId = DEFAULT_SCENARIO_ID): PersistedSlice {
  return {
    activeScenarioId: scenarioId,
    dataset: getRuntimeScenarioDataset(scenarioId),
  };
}

function freshSlice(scenarioId = DEFAULT_SCENARIO_ID): PersistedSlice {
  return {
    activeScenarioId: scenarioId,
    dataset: getScenarioDataset(scenarioId),
  };
}

function normalizePersistedState(value: unknown): PersistedSlice | null {
  if (!value || typeof value !== 'object') return null;
  const candidate = value as Partial<PersistedSlice>;
  if (!candidate.activeScenarioId || !isScenarioDataset(candidate.dataset))
    return null;
  if (candidate.dataset.meta.id !== candidate.activeScenarioId) return null;
  return {
    activeScenarioId: candidate.activeScenarioId,
    dataset: structuredClone(candidate.dataset),
  };
}

export function recoverPersistedState(
  value: unknown,
  persistedVersion: number,
): PersistedSlice {
  if (persistedVersion !== STORE_VERSION) return freshSlice();
  return normalizePersistedState(value) ?? freshSlice();
}

function createAuditEvent(
  dataset: ScenarioDataset,
  entityType: AuditEvent['entityType'],
  entityId: string,
  action: string,
  detail: string,
  actorId: string,
): AuditEvent {
  const sequence = dataset.auditEvents.length + 1;
  return {
    id: `AUD-${dataset.meta.id}-LOCAL-${String(sequence).padStart(3, '0')}`,
    entityType,
    entityId,
    action,
    detail,
    actorId,
    occurredAt: `2026-10-10T19:${String(sequence).padStart(2, '0')}:00+08:00`,
    isPrototype: true,
  };
}

export const useInspectFlowStore = create<InspectFlowStore>()((set, get) => ({
  ...initialSlice(),
  loadScenario: (scenarioId) => {
    saveRuntimeScenarioDataset(get().dataset);
    set(initialSlice(scenarioId));
  },
  getCaseById: (caseId) =>
    get().dataset.cases.find((item) => item.id === caseId),
  updateCaseStatus: (caseId, status, actorId = 'USR-OPS-001') =>
    set(({ dataset, activeScenarioId }) => {
      const target = dataset.cases.find((item) => item.id === caseId);
      if (!target || target.status === status)
        return { dataset, activeScenarioId };
      const next = structuredClone(dataset);
      const nextTarget = next.cases.find((item) => item.id === caseId);
      if (!nextTarget) return { dataset, activeScenarioId };
      const previous = nextTarget.status;
      nextTarget.status = status;
      nextTarget.updatedAt = '2026-10-10T19:00:00+08:00';
      next.auditEvents.push(
        createAuditEvent(
          next,
          'case',
          caseId,
          'CASE_STATUS_UPDATED',
          `案件狀態由 ${previous} 更新為 ${status}`,
          actorId,
        ),
      );
      saveRuntimeScenarioDataset(next);
      return { dataset: next, activeScenarioId };
    }),
  updateTaskStatus: (taskId, status, actorId = 'USR-OPS-001') =>
    set(({ dataset, activeScenarioId }) => {
      const target = dataset.tasks.find((item) => item.id === taskId);
      if (!target || target.status === status)
        return { dataset, activeScenarioId };
      const next = structuredClone(dataset);
      const nextTarget = next.tasks.find((item) => item.id === taskId);
      if (!nextTarget) return { dataset, activeScenarioId };
      const previous = nextTarget.status;
      nextTarget.status = status;
      next.auditEvents.push(
        createAuditEvent(
          next,
          'task',
          taskId,
          'TASK_STATUS_UPDATED',
          `任務狀態由 ${previous} 更新為 ${status}`,
          actorId,
        ),
      );
      saveRuntimeScenarioDataset(next);
      return { dataset: next, activeScenarioId };
    }),
  updateVehicleStatus: (vehicleId, status, reason, actorId = 'USR-OPS-001') =>
    set(({ dataset, activeScenarioId }) => {
      const target = dataset.vehicles.find((item) => item.id === vehicleId);
      if (!target || target.availability === status)
        return { dataset, activeScenarioId };
      const next = structuredClone(dataset);
      const nextTarget = next.vehicles.find((item) => item.id === vehicleId);
      if (!nextTarget) return { dataset, activeScenarioId };
      const previous = nextTarget.availability;
      nextTarget.availability = status;
      next.vehicleStatusEvents.push({
        id: `VSE-${next.meta.id}-LOCAL-${next.vehicleStatusEvents.length + 1}`,
        vehicleId,
        from: previous,
        to: status,
        reason,
        occurredAt: '2026-10-10T19:00:00+08:00',
        actorId,
        isPrototype: true,
      });
      next.auditEvents.push(
        createAuditEvent(
          next,
          'vehicle',
          vehicleId,
          'VEHICLE_STATUS_UPDATED',
          `${previous} → ${status}：${reason}`,
          actorId,
        ),
      );
      saveRuntimeScenarioDataset(next);
      return { dataset: next, activeScenarioId };
    }),
  submitReview: (input) => {
    const validation = validateReviewSubmission(input);
    if (!validation.ok) return validation;
    const { dataset, activeScenarioId } = get();
    const targetCase = dataset.cases.find((item) => item.id === input.caseId);
    const vehicle = dataset.vehicles.find(
      (item) => item.id === targetCase?.vehicleId,
    );
    if (!targetCase || !vehicle || !input.outcome) {
      return {
        ok: false,
        errors: { case: '找不到目前案件或車輛，請重新載入展示案例。' },
      };
    }

    const next = structuredClone(dataset);
    const nextCase = next.cases.find((item) => item.id === input.caseId)!;
    const nextVehicle = next.vehicles.find(
      (item) => item.id === nextCase.vehicleId,
    )!;
    const nextFinding = input.findingId
      ? next.findings.find((item) => item.id === input.findingId)
      : undefined;
    const reviewedAt = `2026-10-10T19:${String(
      10 + next.reviewDecisions.length,
    ).padStart(2, '0')}:00+08:00`;
    const originalType = nextFinding?.type;
    const originalSeverity = nextFinding?.severity;

    if (nextFinding) {
      if (input.correctedType) nextFinding.type = input.correctedType;
      if (input.correctedSeverity)
        nextFinding.severity = input.correctedSeverity;
      if (input.outcome === 'NOT_DAMAGE') {
        nextFinding.possiblyNew = false;
        nextFinding.evidenceState = 'sufficient';
      }
      if (
        input.outcome === 'EVIDENCE_INSUFFICIENT' ||
        input.outcome === 'REQUEST_MORE_EVIDENCE'
      ) {
        nextFinding.possiblyNew = null;
        nextFinding.evidenceState = 'insufficient';
      }
      if (input.outcome === 'CONFIRMED_ANOMALY') {
        nextFinding.possiblyNew = true;
        nextFinding.evidenceState = 'sufficient';
      }
    }

    next.reviewDecisions.push({
      id: `REV-${next.meta.id}-${String(next.reviewDecisions.length + 1).padStart(3, '0')}`,
      caseId: input.caseId,
      findingId: input.findingId,
      outcome: input.outcome,
      correctedType: input.correctedType,
      correctedSeverity: input.correctedSeverity,
      vehicleStatus: input.vehicleStatus,
      reason: input.reason.trim(),
      note: input.note.trim(),
      reviewerId: input.reviewerId,
      reviewedAt,
      isPrototype: true,
    });
    next.auditEvents.push(
      createAuditEvent(
        next,
        'case',
        input.caseId,
        'MANUAL_REVIEW_SUBMITTED',
        `人工覆核：${input.outcome}；理由：${input.reason.trim()}`,
        input.reviewerId,
      ),
    );

    if (
      nextFinding &&
      (originalType !== nextFinding.type ||
        originalSeverity !== nextFinding.severity)
    ) {
      next.auditEvents.push(
        createAuditEvent(
          next,
          'case',
          input.caseId,
          'FINDING_CORRECTED',
          `Finding 修正：${originalType}/${originalSeverity} → ${nextFinding.type}/${nextFinding.severity}`,
          input.reviewerId,
        ),
      );
    }

    const previousCaseStatus = nextCase.status;
    nextCase.status = reviewedCaseStatus(
      input.outcome,
      nextFinding?.type,
      previousCaseStatus,
    );
    nextCase.updatedAt = reviewedAt;
    nextCase.reviewerId = input.reviewerId;
    if (previousCaseStatus !== nextCase.status) {
      next.auditEvents.push(
        createAuditEvent(
          next,
          'case',
          input.caseId,
          'CASE_STATUS_UPDATED',
          `案件狀態由 ${previousCaseStatus} 更新為 ${nextCase.status}`,
          input.reviewerId,
        ),
      );
    }

    if (nextVehicle.availability !== input.vehicleStatus) {
      const previousVehicleStatus = nextVehicle.availability;
      nextVehicle.availability = input.vehicleStatus;
      next.vehicleStatusEvents.push({
        id: `VSE-${next.meta.id}-REVIEW-${next.vehicleStatusEvents.length + 1}`,
        vehicleId: nextVehicle.id,
        from: previousVehicleStatus,
        to: input.vehicleStatus,
        reason: input.reason.trim(),
        occurredAt: reviewedAt,
        actorId: input.reviewerId,
        isPrototype: true,
      });
      next.auditEvents.push(
        createAuditEvent(
          next,
          'vehicle',
          nextVehicle.id,
          'VEHICLE_STATUS_UPDATED',
          `${previousVehicleStatus} → ${input.vehicleStatus}；理由：${input.reason.trim()}`,
          input.reviewerId,
        ),
      );
    }

    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, errors: {} };
  },
  createTask: (input) => {
    const { dataset, activeScenarioId } = get();
    const currentCase = dataset.cases.find((item) => item.id === input.caseId);
    if (!currentCase)
      return { ok: false, message: '找不到案件，請重新載入展示案例。' };
    const duplicate = dataset.tasks.find(
      (task) =>
        task.caseId === input.caseId &&
        task.type === input.type &&
        task.status !== 'CANCELLED',
    );
    if (duplicate) {
      return {
        ok: false,
        message: `相同類型的有效任務已存在：${duplicate.id}`,
        entityId: duplicate.id,
      };
    }
    const rental = dataset.rentals.find(
      (item) => item.id === currentCase.rentalId,
    );
    const next = structuredClone(dataset);
    const taskId = `TSK-${next.meta.id}-${input.type.toUpperCase()}-${String(
      next.tasks.length + 1,
    ).padStart(3, '0')}`;
    const toolMap: Record<Exclude<TaskType, 'claim_review'>, string[]> = {
      cleaning: ['外部營運系統 API', '完工影像回傳'],
      inspection: ['外部營運系統 API', '保養結果回傳'],
      repair: ['外部營運系統 API', '維修結果回傳'],
      suspension: ['外部營運系統 API', '車輛狀態同步'],
    };
    const taskPriority = input.priority ?? currentCase.priority;
    next.tasks.push({
      id: taskId,
      caseId: input.caseId,
      type: input.type,
      status: 'PENDING',
      title: input.title.trim() || `處理 ${currentCase.title}`,
      location: rental?.returnLocation ?? '未提供',
      etaLabel:
        taskPriority === 'urgent'
          ? '展示 ETA：急迫'
          : taskPriority === 'high'
            ? '展示 ETA：常件'
            : '展示 ETA：緩件',
      priority: taskPriority,
      requiredSkills: [input.type],
      requiredTools: toolMap[input.type],
      reservationRisk: currentCase.priority !== 'normal',
      progressNote: '處理請求已送出，等待外部系統回傳進度',
      isPrototype: true,
    });
    next.auditEvents.push(
      createAuditEvent(
        next,
        'task',
        taskId,
        'TASK_CREATED',
        `由案件 ${input.caseId} 建立 ${input.type} 任務`,
        input.actorId,
      ),
    );
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, message: '任務已建立。', entityId: taskId };
  },
  requestClaim: (caseId, actorId = 'USR-OPS-001') => {
    const { dataset, activeScenarioId } = get();
    const currentCase = dataset.cases.find((item) => item.id === caseId);
    if (!currentCase) {
      return { ok: false, message: '找不到案件，請重新載入展示資料。' };
    }
    const existing = dataset.tasks.find(
      (task) =>
        task.caseId === caseId &&
        task.type === 'claim_review' &&
        task.status !== 'CANCELLED',
    );
    if (existing) {
      return {
        ok: false,
        message: '索賠請求已送出。',
        entityId: existing.id,
      };
    }
    const rental = dataset.rentals.find(
      (item) => item.id === currentCase.rentalId,
    );
    const next = structuredClone(dataset);
    const taskId = `TSK-${next.meta.id}-CLAIM-${String(
      next.tasks.length + 1,
    ).padStart(3, '0')}`;
    next.tasks.push({
      id: taskId,
      caseId,
      type: 'claim_review',
      status: 'PENDING',
      title: `${currentCase.title}索賠請求`,
      location: rental?.returnLocation ?? '未提供',
      etaLabel: null,
      priority: currentCase.priority,
      requiredSkills: [],
      requiredTools: ['索賠系統 API', '車況證據包'],
      reservationRisk: false,
      progressNote: '索賠請求與證據包已送出',
      isPrototype: true,
    });
    next.auditEvents.push(
      createAuditEvent(
        next,
        'claim',
        caseId,
        'CLAIM_REQUEST_SENT',
        '索賠請求與車況證據包已透過 API 送出',
        actorId,
      ),
    );
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, message: '索賠請求已送出。', entityId: taskId };
  },
  transitionTask: (taskId, nextStatus, actorId) => {
    const { dataset, activeScenarioId } = get();
    const task = dataset.tasks.find((item) => item.id === taskId);
    if (!task) return { ok: false, message: '找不到任務。' };
    if (!legalTaskTransitions[task.status]?.includes(nextStatus)) {
      return {
        ok: false,
        message: `不能由 ${task.status} 直接轉為 ${nextStatus}。`,
      };
    }
    const next = structuredClone(dataset);
    const nextTask = next.tasks.find((item) => item.id === taskId)!;
    const previous = nextTask.status;
    nextTask.status = nextStatus;
    nextTask.progressNote =
      nextStatus === 'IN_PROGRESS'
        ? nextTask.type === 'repair'
          ? '合作維修廠處理中'
          : '現場人員處理中'
        : '完工影像已回傳，等待複檢';
    if (nextStatus === 'WAITING_REVIEW') {
      const currentCase = next.cases.find(
        (item) => item.id === nextTask.caseId,
      );
      const finding = next.findings.find((item) =>
        currentCase?.findingIds.includes(item.id),
      );
      if (
        !next.completionReviews.some(
          (item) => item.taskId === taskId && item.result === 'PENDING',
        )
      ) {
        next.completionReviews.push({
          id: `CMP-${next.meta.id}-${String(next.completionReviews.length + 1).padStart(3, '0')}`,
          taskId,
          zone: finding?.zone ?? 'leftSide',
          originalImage:
            next.meta.id === 'S02'
              ? '/interior_dirty_best.png'
              : '/exterior_damage_wide.png',
          completionImage:
            next.meta.id === 'S02'
              ? '/interior_dirty_best.png'
              : '/exterior_clean_best.png',
          sameRegion: true,
          result: 'PENDING',
          reason: '',
          reviewerId: null,
          reviewedAt: null,
          isPrototype: true,
        });
      }
    }
    next.auditEvents.push(
      createAuditEvent(
        next,
        'task',
        taskId,
        'TASK_STATUS_UPDATED',
        `${previous} → ${nextStatus}`,
        actorId,
      ),
    );
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, message: '任務進度已更新。' };
  },
  reviewCompletion: (taskId, result, reason, actorId) => {
    if (!reason.trim()) return { ok: false, message: '完工複檢必須填寫理由。' };
    const { dataset, activeScenarioId } = get();
    const task = dataset.tasks.find((item) => item.id === taskId);
    if (!task || task.status !== 'WAITING_REVIEW')
      return { ok: false, message: '任務目前不在待複檢狀態。' };
    const next = structuredClone(dataset);
    const review = [...next.completionReviews]
      .reverse()
      .find((item) => item.taskId === taskId && item.result === 'PENDING');
    if (!review) return { ok: false, message: '找不到待複檢的完工影像。' };
    review.result = result;
    review.reason = reason.trim();
    review.reviewerId = actorId;
    review.reviewedAt = '2026-10-10T19:45:00+08:00';
    const nextTask = next.tasks.find((item) => item.id === taskId)!;
    nextTask.status = result === 'PASSED' ? 'COMPLETED' : 'RETURNED';
    nextTask.progressNote =
      result === 'PASSED' ? '完工複檢通過' : '複檢未通過，退回補處理';
    next.auditEvents.push(
      createAuditEvent(
        next,
        'task',
        taskId,
        result === 'PASSED'
          ? 'COMPLETION_REVIEW_PASSED'
          : 'COMPLETION_REVIEW_RETURNED',
        reason.trim(),
        actorId,
      ),
    );
    if (
      result === 'PASSED' &&
      next.meta.id === 'S06' &&
      nextTask.type === 'cleaning' &&
      !next.tasks.some(
        (item) =>
          item.caseId === nextTask.caseId &&
          item.type === 'inspection' &&
          item.status !== 'CANCELLED',
      )
    ) {
      const currentCase = next.cases.find(
        (item) => item.id === nextTask.caseId,
      );
      const followUpId = `TSK-${next.meta.id}-INSPECT-${String(next.tasks.length + 1).padStart(3, '0')}`;
      next.tasks.push({
        id: followUpId,
        caseId: nextTask.caseId,
        type: 'inspection',
        status: 'PENDING',
        title: '清潔後同區域重新掃描與車況判讀',
        location: nextTask.location,
        etaLabel: '展示 ETA：15 分鐘',
        priority: currentCase?.priority ?? 'high',
        requiredSkills: ['inspection'],
        requiredTools: ['InspectFlow 同區域掃描'],
        reservationRisk: true,
        progressNote: '等待巡檢人員接單',
        isPrototype: true,
      });
      next.auditEvents.push(
        createAuditEvent(
          next,
          'task',
          followUpId,
          'FOLLOW_UP_INSPECTION_CREATED',
          '清潔完成後必須回到同一區域重新掃描，尚不可恢復 READY。',
          actorId,
        ),
      );
    }
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return {
      ok: true,
      message: result === 'PASSED' ? '完工複檢已通過。' : '已退回補處理。',
    };
  },
  authorizeVehicleRelease: (caseId, reason, actorId) => {
    if (!reason.trim())
      return { ok: false, message: '重新上線必須填寫授權理由。' };
    const { dataset, activeScenarioId } = get();
    const gate = evaluateReleaseGate(dataset, caseId);
    if (!gate.canAuthorize) {
      return {
        ok: false,
        message: '必要任務或完工複檢尚未全部通過，不能重新上線。',
      };
    }
    const currentCase = dataset.cases.find((item) => item.id === caseId);
    if (!currentCase) return { ok: false, message: '找不到案件。' };
    const next = structuredClone(dataset);
    const nextCase = next.cases.find((item) => item.id === caseId)!;
    const vehicle = next.vehicles.find(
      (item) => item.id === nextCase.vehicleId,
    )!;
    next.releaseAuthorizations.push({
      id: `REL-${next.meta.id}-${String(next.releaseAuthorizations.length + 1).padStart(3, '0')}`,
      caseId,
      vehicleId: vehicle.id,
      reason: reason.trim(),
      authorizedBy: actorId,
      authorizedAt: '2026-10-10T19:50:00+08:00',
      isPrototype: true,
    });
    const previous = vehicle.availability;
    vehicle.availability = 'READY';
    nextCase.status = 'RESOLVED';
    nextCase.updatedAt = '2026-10-10T19:50:00+08:00';
    next.vehicleStatusEvents.push({
      id: `VSE-${next.meta.id}-RELEASE-${next.vehicleStatusEvents.length + 1}`,
      vehicleId: vehicle.id,
      from: previous,
      to: 'READY',
      reason: reason.trim(),
      occurredAt: '2026-10-10T19:50:00+08:00',
      actorId,
      isPrototype: true,
    });
    next.auditEvents.push(
      createAuditEvent(
        next,
        'vehicle',
        vehicle.id,
        'VEHICLE_RELEASE_AUTHORIZED',
        `人工授權重新上線；理由：${reason.trim()}`,
        actorId,
      ),
    );
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, message: '人工授權完成，車輛已恢復 READY。' };
  },
  submitClaimDecision: (input) => {
    const validation = validateClaimDecision(input);
    if (!validation.ok) return validation;
    const { dataset, activeScenarioId } = get();
    const currentCase = dataset.cases.find((item) => item.id === input.caseId);
    const claimFinding = dataset.findings.find(
      (finding) =>
        currentCase?.findingIds.includes(finding.id) &&
        finding.possiblyNew === true &&
        ['scratch', 'dent', 'crack'].includes(finding.type),
    );
    if (!currentCase || !claimFinding) {
      return { ok: false, message: '此案件不是目前可操作的索賠候選。' };
    }
    const next = structuredClone(dataset);
    const nextCase = next.cases.find((item) => item.id === input.caseId)!;
    const reviewedAt = `2026-10-10T19:${String(40 + next.claimDecisions.length).padStart(2, '0')}:00+08:00`;
    next.claimDecisions.push({
      id: `CLM-${next.meta.id}-${String(next.claimDecisions.length + 1).padStart(3, '0')}`,
      caseId: input.caseId,
      outcome: input.outcome as ClaimOutcome,
      reason: input.reason.trim(),
      note: input.note.trim(),
      reviewerId: input.reviewerId,
      reviewedAt,
      isPrototype: true,
    });
    const claimTask = next.tasks.find(
      (task) => task.caseId === input.caseId && task.type === 'claim_review',
    );
    const resolved =
      input.outcome === 'EVIDENCE_SUFFICIENT' ||
      input.outcome === 'NOT_NEW_DAMAGE';
    if (claimTask) {
      claimTask.status = resolved ? 'COMPLETED' : 'RETURNED';
      claimTask.progressNote = resolved
        ? '人工索賠證據結論已完成'
        : '等待補充證據後重新覆核';
    }
    nextCase.status = resolved ? 'RESOLVED' : 'PENDING_INSPECTION';
    nextCase.updatedAt = reviewedAt;
    nextCase.reviewerId = input.reviewerId;
    const claimAudit = createAuditEvent(
      next,
      'claim',
      input.caseId,
      'CLAIM_DECISION_SUBMITTED',
      `人工索賠結論：${input.outcome}；理由：${input.reason.trim()}`,
      input.reviewerId,
    );
    claimAudit.occurredAt = reviewedAt;
    next.auditEvents.push(claimAudit);
    saveRuntimeScenarioDataset(next);
    set({ dataset: next, activeScenarioId });
    return { ok: true, message: '人工索賠結論已儲存並寫入稽核軌跡。' };
  },
  resetActiveScenario: () =>
    set(({ activeScenarioId }) => {
      const fresh = getScenarioDataset(activeScenarioId);
      saveRuntimeScenarioDataset(fresh);
      return { activeScenarioId, dataset: fresh };
    }),
}));
