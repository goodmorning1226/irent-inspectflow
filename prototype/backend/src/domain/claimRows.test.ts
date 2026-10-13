import { describe, expect, it } from 'vitest';

import { getScenarioDataset } from '../data/scenarios';
import { buildClaimRows } from './claimRows';

describe('claim queue', () => {
  it('does not show an unreviewed damage case until it is explicitly queued', () => {
    const dataset = structuredClone(getScenarioDataset('S07'));

    expect(
      buildClaimRows(dataset).some((row) => row.caseId === 'CASE-S07-002'),
    ).toBe(false);

    const target = dataset.cases.find(
      (currentCase) => currentCase.id === 'CASE-S07-002',
    );
    expect(target).toBeDefined();
    target!.status = 'CLAIM_REVIEW';

    expect(
      buildClaimRows(dataset).some((row) => row.caseId === 'CASE-S07-002'),
    ).toBe(true);
  });
});
