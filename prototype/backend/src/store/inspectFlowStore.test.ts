import { beforeEach, describe, expect, it } from 'vitest';

import { getScenarioDataset, SCENARIO_IDS } from '../data/scenarios';
import { buildAuditTimeline } from '../domain/auditTimeline';
import {
  DEFAULT_SCENARIO_ID,
  evaluateReleaseGate,
  recoverPersistedState,
  STORE_VERSION,
  useInspectFlowStore,
} from './inspectFlowStore';

describe('InspectFlow prototype store', () => {
  beforeEach(() => {
    useInspectFlowStore.getState().loadScenario(DEFAULT_SCENARIO_ID);
  });

  it('loads all seven fixed scenarios with matching identifiers', () => {
    for (const scenarioId of SCENARIO_IDS) {
      const dataset = getScenarioDataset(scenarioId);
      expect(dataset.meta.id).toBe(scenarioId);
      expect(dataset.schemaVersion).toBe('prototype-1.0');
      expect(dataset.vehicles.length).toBeGreaterThan(0);
    }
  });

  it('returns to the same initial data after a local state update and reset', () => {
    useInspectFlowStore.getState().loadScenario('S02');
    const initial = getScenarioDataset('S02');
    const caseId = initial.cases[0]?.id;
    expect(caseId).toBeDefined();
    useInspectFlowStore.getState().updateCaseStatus(caseId!, 'RESOLVED');
    expect(useInspectFlowStore.getState().dataset).not.toEqual(initial);

    useInspectFlowStore.getState().resetActiveScenario();
    expect(useInspectFlowStore.getState().dataset).toEqual(initial);
  });

  it('falls back to S01 when persisted data has a different version or invalid shape', () => {
    expect(recoverPersistedState({}, STORE_VERSION - 1).activeScenarioId).toBe(
      'S01',
    );
    expect(
      recoverPersistedState({ broken: true }, STORE_VERSION).dataset,
    ).toEqual(getScenarioDataset('S01'));
  });

  it('requires a reason and records review, state transitions and audit events', () => {
    useInspectFlowStore.getState().loadScenario('S02');
    const initialAuditCount =
      useInspectFlowStore.getState().dataset.auditEvents.length;
    const invalid = useInspectFlowStore.getState().submitReview({
      caseId: 'CASE-S02-001',
      findingId: 'FND-DEMO-INTERIOR-001',
      outcome: 'CONFIRMED_ANOMALY',
      correctedType: 'stain',
      correctedSeverity: 'medium',
      vehicleStatus: 'CLEANING',
      reason: '   ',
      note: '',
      reviewerId: 'USR-OPS-001',
    });
    expect(invalid.ok).toBe(false);
    expect(invalid.errors.reason).toBeDefined();
    expect(useInspectFlowStore.getState().dataset.auditEvents).toHaveLength(
      initialAuditCount,
    );

    const valid = useInspectFlowStore.getState().submitReview({
      caseId: 'CASE-S02-001',
      findingId: 'FND-DEMO-INTERIOR-001',
      outcome: 'CONFIRMED_ANOMALY',
      correctedType: 'stain',
      correctedSeverity: 'medium',
      vehicleStatus: 'CLEANING',
      reason: '污漬在合格影像中清楚可見，需先完成清潔。',
      note: 'Prototype 測試',
      reviewerId: 'USR-OPS-001',
    });
    const reviewed = useInspectFlowStore.getState().dataset;
    expect(valid.ok).toBe(true);
    expect(reviewed.reviewDecisions).toHaveLength(1);
    expect(reviewed.cases[0]?.status).toBe('PENDING_CLEANING');
    expect(reviewed.vehicles[0]?.availability).toBe('CLEANING');
    expect(
      reviewed.auditEvents.some(
        (event) => event.action === 'MANUAL_REVIEW_SUBMITTED',
      ),
    ).toBe(true);
    expect(
      reviewed.auditEvents.some(
        (event) => event.action === 'VEHICLE_STATUS_UPDATED',
      ),
    ).toBe(true);

    useInspectFlowStore.getState().loadScenario('S04');
    useInspectFlowStore.getState().submitReview({
      caseId: 'CASE-S04-001',
      findingId: 'FND-S04-REFLECTION-001',
      outcome: 'NOT_DAMAGE',
      correctedType: 'reflection',
      correctedSeverity: 'low',
      vehicleStatus: 'READY',
      reason: '疑似痕跡會隨視角移動，確認為反光。',
      note: '',
      reviewerId: 'USR-OPS-001',
    });
    expect(
      useInspectFlowStore.getState().dataset.reviewDecisions[0]?.outcome,
    ).toBe('NOT_DAMAGE');

    useInspectFlowStore.getState().loadScenario('S05');
    useInspectFlowStore.getState().submitReview({
      caseId: 'CASE-S05-001',
      findingId: 'FND-S05-UNKNOWN-001',
      outcome: 'EVIDENCE_INSUFFICIENT',
      correctedType: 'unknown',
      correctedSeverity: 'unknown',
      vehicleStatus: 'REINSPECTION_REQUIRED',
      reason: '缺少同區域歷史基準，無法判斷是否為新增異常。',
      note: '需補件',
      reviewerId: 'USR-OPS-001',
    });
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('REINSPECTION_REQUIRED');
    expect(
      useInspectFlowStore.getState().dataset.findings[0]?.evidenceState,
    ).toBe('insufficient');
  });

  it('prevents duplicate tasks, enforces transitions and requires evidence plus human authorization before READY', () => {
    useInspectFlowStore.getState().loadScenario('S02');
    const caseId = 'CASE-S02-001';

    useInspectFlowStore.getState().submitReview({
      caseId,
      findingId: 'FND-DEMO-INTERIOR-001',
      outcome: 'CONFIRMED_ANOMALY',
      correctedType: 'stain',
      correctedSeverity: 'medium',
      vehicleStatus: 'CLEANING',
      reason: '確認為需要處理的座墊污漬。',
      note: '',
      reviewerId: 'USR-OPS-001',
    });
    const created = useInspectFlowStore.getState().createTask({
      caseId,
      type: 'cleaning',
      title: '清潔後座右側座墊',
      actorId: 'USR-OPS-001',
    });
    expect(created.ok).toBe(true);
    const taskId = created.entityId!;
    const duplicate = useInspectFlowStore.getState().createTask({
      caseId,
      type: 'cleaning',
      title: '重複清潔任務',
      actorId: 'USR-OPS-001',
    });
    expect(duplicate.ok).toBe(false);
    expect(useInspectFlowStore.getState().dataset.tasks).toHaveLength(1);

    expect(
      useInspectFlowStore
        .getState()
        .transitionTask(taskId, 'IN_PROGRESS', 'USR-OPS-001').ok,
    ).toBe(false);
    expect(
      useInspectFlowStore
        .getState()
        .assignTask(taskId, 'WRK-CLEAN-01', '', 'USR-DISPATCH-001').ok,
    ).toBe(true);
    expect(
      useInspectFlowStore
        .getState()
        .transitionTask(taskId, 'IN_PROGRESS', 'USR-OPS-001').ok,
    ).toBe(true);
    expect(
      useInspectFlowStore
        .getState()
        .transitionTask(taskId, 'WAITING_REVIEW', 'USR-OPS-001').ok,
    ).toBe(true);

    expect(
      useInspectFlowStore
        .getState()
        .authorizeVehicleRelease(caseId, '提前放行', 'USR-OPS-001').ok,
    ).toBe(false);
    expect(
      useInspectFlowStore
        .getState()
        .reviewCompletion(
          taskId,
          'PASSED',
          '同區域完工影像確認污漬已清除。',
          'USR-OPS-001',
        ).ok,
    ).toBe(true);

    const readyForAuthorization = evaluateReleaseGate(
      useInspectFlowStore.getState().dataset,
      caseId,
    );
    expect(readyForAuthorization.canAuthorize).toBe(true);
    expect(readyForAuthorization.ready).toBe(false);
    expect(
      useInspectFlowStore
        .getState()
        .authorizeVehicleRelease(
          caseId,
          '必要任務及完工證據均已通過人工確認。',
          'USR-OPS-001',
        ).ok,
    ).toBe(true);
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('READY');
    expect(
      evaluateReleaseGate(useInspectFlowStore.getState().dataset, caseId).ready,
    ).toBe(true);
  });

  it('creates a required same-region inspection after S06 cleaning passes', () => {
    useInspectFlowStore.getState().loadScenario('S06');
    const taskId = 'TSK-S06-CLEAN-001';
    const caseId = 'CASE-S06-001';

    useInspectFlowStore
      .getState()
      .transitionTask(taskId, 'IN_PROGRESS', 'USR-OPS-001');
    useInspectFlowStore
      .getState()
      .transitionTask(taskId, 'WAITING_REVIEW', 'USR-OPS-001');
    expect(
      useInspectFlowStore
        .getState()
        .reviewCompletion(
          taskId,
          'PASSED',
          '泥污已清潔完成，需回到同區域重新判讀。',
          'USR-OPS-001',
        ).ok,
    ).toBe(true);

    const followUp = useInspectFlowStore
      .getState()
      .dataset.tasks.find((task) => task.type === 'inspection');
    expect(followUp?.status).toBe('PENDING');
    expect(
      evaluateReleaseGate(useInspectFlowStore.getState().dataset, caseId),
    ).toMatchObject({
      tasksComplete: false,
      canAuthorize: false,
      ready: false,
    });

    useInspectFlowStore
      .getState()
      .assignTask(followUp!.id, 'WRK-CLEAN-01', '', 'USR-DISPATCH-001');
    useInspectFlowStore
      .getState()
      .transitionTask(followUp!.id, 'IN_PROGRESS', 'USR-OPS-001');
    useInspectFlowStore
      .getState()
      .transitionTask(followUp!.id, 'WAITING_REVIEW', 'USR-OPS-001');
    useInspectFlowStore
      .getState()
      .reviewCompletion(
        followUp!.id,
        'PASSED',
        '清潔後同區域重新掃描，未發現需要繼續處理的損傷。',
        'USR-OPS-001',
      );
    expect(
      evaluateReleaseGate(useInspectFlowStore.getState().dataset, caseId)
        .canAuthorize,
    ).toBe(true);
    expect(
      useInspectFlowStore
        .getState()
        .authorizeVehicleRelease(
          caseId,
          '清潔及同區域重新判讀均已完成。',
          'USR-OPS-001',
        ).ok,
    ).toBe(true);
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('READY');
  });

  it('keeps S07 offline until repair evidence and human release are complete', () => {
    useInspectFlowStore.getState().loadScenario('S07');
    const taskId = 'TSK-S07-REPAIR-001';
    const caseId = 'CASE-S07-001';
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('OFFLINE');
    expect(
      useInspectFlowStore
        .getState()
        .authorizeVehicleRelease(caseId, '嘗試提前上線', 'USR-OPS-001').ok,
    ).toBe(false);
    useInspectFlowStore
      .getState()
      .transitionTask(taskId, 'IN_PROGRESS', 'USR-OPS-001');
    useInspectFlowStore
      .getState()
      .transitionTask(taskId, 'WAITING_REVIEW', 'USR-OPS-001');
    useInspectFlowStore
      .getState()
      .reviewCompletion(
        taskId,
        'PASSED',
        '維修完成且同區域安全檢查通過。',
        'USR-OPS-001',
      );
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('OFFLINE');
    expect(
      useInspectFlowStore
        .getState()
        .authorizeVehicleRelease(
          caseId,
          '維修、完工證據及安全檢查均已通過。',
          'USR-OPS-001',
        ).ok,
    ).toBe(true);
    expect(
      useInspectFlowStore.getState().dataset.vehicles[0]?.availability,
    ).toBe('READY');
  });

  it('restricts claim decisions, requires a reason and appends a chronological audit event', () => {
    useInspectFlowStore.getState().loadScenario('S03');
    const unauthorized = useInspectFlowStore.getState().submitClaimDecision({
      caseId: 'CASE-S03-001',
      outcome: 'EVIDENCE_SUFFICIENT',
      reason: '證據可比。',
      note: '',
      reviewerId: 'USR-OPS-001',
      actorRole: 'operations',
    });
    expect(unauthorized.ok).toBe(false);
    expect(useInspectFlowStore.getState().dataset.claimDecisions).toHaveLength(
      0,
    );

    const missingReason = useInspectFlowStore.getState().submitClaimDecision({
      caseId: 'CASE-S03-001',
      outcome: 'EVIDENCE_SUFFICIENT',
      reason: ' ',
      note: '',
      reviewerId: 'USR-CLAIM-001',
      actorRole: 'claimReviewer',
    });
    expect(missingReason.ok).toBe(false);

    const valid = useInspectFlowStore.getState().submitClaimDecision({
      caseId: 'CASE-S03-001',
      outcome: 'EVIDENCE_SUFFICIENT',
      reason: '前後影像同區域可比，三個補掃視角均持續看見痕跡。',
      note: '僅確認證據足夠，不代表認定責任。',
      reviewerId: 'USR-CLAIM-001',
      actorRole: 'claimReviewer',
    });
    const decided = useInspectFlowStore.getState().dataset;
    expect(valid.ok).toBe(true);
    expect(decided.claimDecisions).toHaveLength(1);
    expect(
      decided.auditEvents.some(
        (event) => event.action === 'CLAIM_DECISION_SUBMITTED',
      ),
    ).toBe(true);
    const timeline = buildAuditTimeline(decided);
    expect(
      timeline.every(
        (item, index) =>
          index === 0 ||
          new Date(timeline[index - 1]!.occurredAt).getTime() <=
            new Date(item.occurredAt).getTime(),
      ),
    ).toBe(true);
  });
});
