import { describe, expect, it } from 'vitest';

import { getAllScenarioDatasets, getScenarioDataset } from '../data/scenarios';
import { buildAuditTimeline } from './auditTimeline';
import { buildCaseWorkspace } from './caseEvidence';
import { buildCaseRows } from './caseRows';
import { buildTaskRows, buildTaskWorkspace } from './taskRows';

describe('Stage 8 scenario and offline matrix', () => {
  it('keeps S01–S07 aligned with their intended safety and evidence boundaries', () => {
    const expected = {
      S01: { caseStatus: 'RESOLVED', vehicle: 'READY', finding: false },
      S02: {
        caseStatus: 'PENDING_REVIEW',
        vehicle: 'REVIEW_REQUIRED',
        finding: true,
      },
      S03: {
        caseStatus: 'CLAIM_REVIEW',
        vehicle: 'REVIEW_REQUIRED',
        finding: true,
      },
      S04: {
        caseStatus: 'PENDING_REVIEW',
        vehicle: 'REVIEW_REQUIRED',
        finding: true,
      },
      S05: {
        caseStatus: 'PENDING_INSPECTION',
        vehicle: 'REVIEW_REQUIRED',
        finding: true,
      },
      S06: {
        caseStatus: 'PENDING_CLEANING',
        vehicle: 'CLEANING',
        finding: true,
      },
      S07: {
        caseStatus: 'PENDING_REPAIR',
        vehicle: 'OFFLINE',
        finding: true,
      },
    } as const;

    for (const dataset of getAllScenarioDatasets()) {
      const target = expected[dataset.meta.id];
      expect(dataset.cases[0]?.status).toBe(target.caseStatus);
      expect(dataset.vehicles[0]?.availability).toBe(target.vehicle);
      expect((dataset.cases[0]?.findingIds.length ?? 0) > 0).toBe(
        target.finding,
      );
      expect(dataset.meta.dataNotice).toMatch(/Prototype|展示|模型/);
    }
    expect(getScenarioDataset('S05').findings[0]?.possiblyNew).toBeNull();
    expect(
      getScenarioDataset('S06').findings[0]?.limitations.join(''),
    ).toContain('清潔前不可判斷');
    expect(
      new Set(
        getAllScenarioDatasets().map(
          (dataset) => dataset.vehicles[0]?.plateNumber,
        ),
      ).size,
    ).toBe(7);
  });

  it('resolves every case and task deep link from the aggregated queues', () => {
    const active = getScenarioDataset('S01');
    const caseRows = buildCaseRows(active);
    const taskRows = buildTaskRows(active);
    expect(caseRows).toHaveLength(24);
    for (const row of caseRows) {
      const workspace = buildCaseWorkspace(row.id, active);
      expect(workspace?.currentCase.id).toBe(row.id);
      expect(workspace?.zoneEvidence).toHaveLength(6);
      expect(
        new Set(workspace?.zoneEvidence.map((zone) => zone.zoneId)).size,
      ).toBe(6);
      expect(
        workspace?.zoneEvidence.every((zone) => zone.current.src !== null),
      ).toBe(true);
    }
    for (const row of taskRows) {
      expect(buildTaskWorkspace(row.id, active)?.task.id).toBe(row.id);
    }
    expect(taskRows.some((row) => row.type === 'claim_review')).toBe(true);

    const reviewQueue = caseRows.filter(
      (row) =>
        row.status === 'PENDING_REVIEW' &&
        !row.hasActiveTask &&
        !row.inClaimQueue &&
        row.anomalyType !== 'none',
    );
    expect(reviewQueue).toHaveLength(4);
    expect(reviewQueue.some((row) => row.id === 'CASE-S04-001')).toBe(true);
    expect(reviewQueue.find((row) => row.id === 'CASE-S04-001')).toMatchObject({
      anomalyType: 'scratch',
      anomalyLabel: '刮痕',
    });

    const headlightWorkspace = buildCaseWorkspace(
      'CASE-S07-001',
      getScenarioDataset('S07'),
    );
    expect(headlightWorkspace?.presentation.current.src).toBe(
      '/headlight_damage_wide.png',
    );
    expect(headlightWorkspace?.presentation.angles[0]?.src).toBe(
      '/headlight_damage_detail.png',
    );
  });

  it('keeps every scenario audit timeline chronological', () => {
    for (const dataset of getAllScenarioDatasets()) {
      const timeline = buildAuditTimeline(dataset);
      expect(
        timeline.every(
          (item, index) =>
            index === 0 ||
            Date.parse(timeline[index - 1]!.occurredAt) <=
              Date.parse(item.occurredAt),
        ),
      ).toBe(true);
    }
  });
});
