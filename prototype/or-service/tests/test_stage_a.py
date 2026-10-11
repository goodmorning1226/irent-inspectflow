import copy
import json
import sys
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from baselines.stage_a import distance_km, recommend


class StageATest(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT/'data/taipei_base.json').read_text())

    def test_coordinate_distance(self):
        a = {'latitude': 0, 'longitude': 0}
        b = {'latitude': 0, 'longitude': 1}
        self.assertEqual(distance_km(a, a), 0)
        self.assertAlmostEqual(distance_km(a, b), 111.195, places=2)
        self.assertEqual(distance_km(a, b), distance_km(b, a))

    def test_priority_and_nearest_eligible(self):
        rows = recommend(self.data)['recommendations']
        weights = {'urgent': 0, 'high': 1, 'normal': 2}
        keys = [(weights[r['priority']], r['deadline_minute'], r['release_minute'], r['task_id']) for r in rows]
        self.assertEqual(keys, sorted(keys))
        self.assertTrue(all(r['priority'] == 'urgent' for r in rows[:2]))
        for row in rows:
            if row['state'] == 'RECOMMENDED':
                self.assertEqual(row['recommended_worker_id'], row['candidates'][0]['worker_id'])
                task = next(t for t in self.data['tasks'] if t['id']==row['task_id'])
                worker = next(w for w in self.data['workers'] if w['id']==row['recommended_worker_id'])
                self.assertTrue(set(task['required_skills']) <= set(worker['skills']))
                self.assertTrue(set(task['required_tools']) <= set(worker['tools']))

    def test_dependencies_and_no_worker(self):
        result = recommend(self.data)
        self.assertEqual(result['summary']['waiting_predecessor'], 4)
        self.data['workers'] = []
        result = recommend(self.data)
        self.assertEqual(result['summary']['no_eligible_worker'], 20)
        self.assertTrue(all(r['recommended_worker_id'] is None for r in result['recommendations']))

    def test_completed_predecessor_unlocks_and_locked_task_preserved(self):
        self.data['tasks'][2]['status'] = 'COMPLETED'
        self.data['tasks'][0]['locked_worker_id'] = 'WRK-03'
        rows = {r['task_id']:r for r in recommend(self.data)['recommendations']}
        self.assertEqual(rows['TSK-021']['state'], 'RECOMMENDED')
        self.assertEqual(rows['TSK-001']['state'], 'SKIPPED')

    def test_repeatable_without_mutation(self):
        before = copy.deepcopy(self.data)
        self.assertEqual(recommend(self.data), recommend(self.data))
        self.assertEqual(self.data, before)

if __name__ == '__main__':
    unittest.main()
