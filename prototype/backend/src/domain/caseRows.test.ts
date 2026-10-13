import { describe, expect, it } from 'vitest';

import { getScenarioDataset } from '../data/scenarios';
import {
  buildCaseRows,
  defaultCaseFilters,
  filterAndSortCaseRows,
} from './caseRows';

describe('case queue filters', () => {
  const rows = buildCaseRows(getScenarioDataset('S01'));

  it('combines search, status and risk filters without leaking unrelated cases', () => {
    const result = filterAndSortCaseRows(rows, {
      ...defaultCaseFilters,
      search: 'CASE-S03',
      status: 'CLAIM_REVIEW',
      risk: 'high',
    });
    expect(result.map((row) => row.id)).toEqual(['CASE-S03-001']);
  });

  it('finds unavailable cases that have an active deadline', () => {
    const result = filterAndSortCaseRows(rows, {
      ...defaultCaseFilters,
      availability: 'unavailable',
      due: 'soon',
    });
    expect(result.length).toBeGreaterThan(0);
    expect(
      result.every((row) => row.availability !== 'READY' && row.isDueSoon),
    ).toBe(true);
  });

  it('keeps dashboard review count consistent with the combined review filter', () => {
    const result = filterAndSortCaseRows(rows, {
      ...defaultCaseFilters,
      status: 'review',
    });
    expect(result.map((row) => row.status).sort()).toEqual([
      'CLAIM_REVIEW',
      'CLAIM_REVIEW',
      'PENDING_REVIEW',
      'PENDING_REVIEW',
      'PENDING_REVIEW',
      'PENDING_REVIEW',
    ]);
  });

  it('keeps exactly four unprocessed cases in the anomaly review queue', () => {
    const result = rows.filter(
      (row) =>
        row.status === 'PENDING_REVIEW' &&
        !row.hasActiveTask &&
        !row.inClaimQueue,
    );

    expect(result.map((row) => row.id).sort()).toEqual([
      'CASE-S02-001',
      'CASE-S02-002',
      'CASE-S04-001',
      'CASE-S07-002',
    ]);
    expect(result).toHaveLength(4);
  });
});
