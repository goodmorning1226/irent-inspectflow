import { describe, expect, it } from 'vitest';

import { getScenarioDataset } from '../data/scenarios';
import { buildCaseWorkspace, formatFindingType } from './caseEvidence';
import { buildCaseRows } from './caseRows';
import { buildClaimRows } from './claimRows';
import { buildFleetRecords } from './fleetRows';
import {
  buildTaskRows,
  buildTaskWorkspace,
  selectProcessingRows,
} from './taskRows';

describe('operations demo consistency', () => {
  const dataset = getScenarioDataset('S01');
  const addedCases = dataset.cases.filter((item) =>
    item.id.startsWith('CASE-S01-OPS-'),
  );

  it('adds fifteen connected records for the three operating queues', () => {
    expect(addedCases).toHaveLength(15);
    expect(
      dataset.vehicles.filter((item) => item.id.startsWith('VEH-S01-OPS-')),
    ).toHaveLength(15);
    for (const currentCase of addedCases) {
      expect(buildCaseWorkspace(currentCase.id, dataset)).not.toBeNull();
    }
  });

  it('keeps the default processing and vehicle lists concise', () => {
    const processing = selectProcessingRows(buildTaskRows(dataset));
    expect(processing).toHaveLength(5);
    expect(processing.map((item) => item.priority)).toEqual([
      'urgent',
      'high',
      'high',
      'high',
      'normal',
    ]);
    const fleet = buildFleetRecords(dataset);
    expect(fleet).toHaveLength(8);
    expect(fleet.some((item) => item.vehicle.availability === 'READY')).toBe(
      true,
    );
    expect(fleet.some((item) => item.vehicle.availability === 'RENTED')).toBe(
      true,
    );
    expect(
      fleet.findIndex((item) => item.vehicle.availability === 'RENTED'),
    ).toBeGreaterThan(
      Math.max(
        ...fleet
          .map((item, index) => ({ item, index }))
          .filter(({ item }) => item.vehicle.availability === 'READY')
          .map(({ index }) => index),
      ),
    );
    const readyCleanliness = fleet
      .filter((item) => item.vehicle.availability === 'READY')
      .map((item) => item.vehicle.cleanliness ?? 'normal');
    expect(readyCleanliness).toEqual(
      [...readyCleanliness].sort(
        (left, right) =>
          (left === 'normal' ? 0 : 1) - (right === 'normal' ? 0 : 1),
      ),
    );
  });

  it('keeps processed task and claim cases out of anomaly review', () => {
    const anomalyQueue = buildCaseRows(dataset).filter(
      (row) =>
        row.status === 'PENDING_REVIEW' &&
        !row.hasActiveTask &&
        !row.inClaimQueue,
    );
    expect(anomalyQueue).toHaveLength(4);
    expect(anomalyQueue[0]?.risk).toBe('urgent');
    expect(anomalyQueue.some((row) => row.id.startsWith('CASE-S01-OPS-'))).toBe(
      false,
    );
  });

  it('uses a clean rear-seat image for normal records and labels dirt by cabin area', () => {
    const normalWorkspace = buildCaseWorkspace('CASE-S01-OPS-001', dataset);
    const normalRearSeat = normalWorkspace?.zoneEvidence.find(
      (zone) => zone.zoneId === 'rearSeat',
    );
    expect(normalRearSeat?.current.src).toBe('/interior_clean_best.png');

    const interiorWorkspace = buildCaseWorkspace(
      'CASE-S02-001',
      getScenarioDataset('S02'),
    );
    expect(formatFindingType(interiorWorkspace!.findings[0]!)).toBe('車內髒污');
  });

  it('resolves every added task and keeps repair plus claim flows parallel', () => {
    const addedTasks = buildTaskRows(dataset).filter((item) =>
      item.id.startsWith('TSK-S01-OPS-'),
    );
    expect(addedTasks).toHaveLength(9);
    for (const task of addedTasks) {
      expect(buildTaskWorkspace(task.id, dataset)).not.toBeNull();
    }

    const parallelCase = dataset.cases.find(
      (item) => item.id === 'CASE-S01-OPS-009',
    );
    expect(parallelCase?.status).toBe('CLAIM_REVIEW');
    expect(
      dataset.tasks.some(
        (item) => item.caseId === parallelCase?.id && item.type === 'repair',
      ),
    ).toBe(true);
    expect(
      buildClaimRows(dataset).some((item) => item.caseId === parallelCase?.id),
    ).toBe(true);
  });
});
