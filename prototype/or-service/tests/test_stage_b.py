import json
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_b import prepare, validate_assignments

class StageBTest(unittest.TestCase):
    def setUp(self):
        self.data=json.loads((ROOT/'data/taipei_base.json').read_text())

    def test_data_preparation(self):
        p=prepare(self.data)
        self.assertEqual(len(p['tasks']),24)
        self.assertTrue(all(c==450 for c in p['capacities'].values()))
        self.assertTrue(all(set(p['tasks'][i]['required_skills'])<=set(p['workers'][k]['skills']) for i,k in p['eligible']))

    def test_missing_skill(self):
        self.data['workers']=[]
        self.assertEqual(prepare(self.data)['eligible'],[])

    def test_locked_task_excluded(self):
        self.data['tasks'][0]['locked_worker_id']='WRK-03'
        self.assertNotIn('TSK-001',prepare(self.data)['tasks'])

    def test_checker_rejects_invalid_skill(self):
        with self.assertRaises(ValueError):
            validate_assignments(prepare(self.data),[dict(task_id='TSK-001',worker_id='WRK-01')])

    def test_checker_rejects_missing_predecessor(self):
        with self.assertRaises(ValueError):
            validate_assignments(prepare(self.data),[dict(task_id='TSK-021',worker_id='WRK-05')])

    def test_checker_rejects_overload_and_duplicate(self):
        p=prepare(self.data)
        p['capacities']['WRK-03']=0
        with self.assertRaises(ValueError):
            validate_assignments(p,[dict(task_id='TSK-001',worker_id='WRK-03')])
        p=prepare(self.data)
        row=dict(task_id='TSK-001',worker_id='WRK-03')
        with self.assertRaises(ValueError):
            validate_assignments(p,[row,row])

    def test_valid_assignment(self):
        p=prepare(self.data)
        loads=validate_assignments(p,[dict(task_id='TSK-003',worker_id='WRK-01'),dict(task_id='TSK-021',worker_id='WRK-05')])
        self.assertEqual(loads['WRK-05'],15)

if __name__=='__main__': unittest.main()
