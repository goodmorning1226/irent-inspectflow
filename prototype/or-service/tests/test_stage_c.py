import copy
import json
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_c import solve,validate_schedule,build_model


def fixture():
    d=json.loads((ROOT/'data/taipei_base.json').read_text())
    d['workers']=[d['workers'][0],d['workers'][4]]
    for w in d['workers']:
        w.update(shift_end_minute=240,break_window=[120,180],break_duration_minutes=30)
    d['workers'][1]['skills']=['inspection'];d['workers'][1]['tools']=['inspection_kit']
    by_id={t['id']:t for t in d['tasks']}
    d['tasks']=[by_id['TSK-003'],by_id['TSK-021']]
    d['tasks'][0].update(duration_minutes=40,release_minute=60,deadline_minute=120)
    d['tasks'][1].update(duration_minutes=15,release_minute=0,deadline_minute=180)
    d['planning']['horizon_minutes']=240
    d['solver_defaults'].update(time_limit_seconds=5,mip_gap=0)
    return d

class StageCTest(unittest.TestCase):
    def test_cross_worker_precedence_release_and_break(self):
        d=fixture();r=solve(d)
        self.assertTrue(r['has_solution']);self.assertEqual(r['validation']['status'],'passed')
        times={t['task_id']:t for t in r['task_schedule']}
        self.assertEqual(len(times),2)
        self.assertNotEqual(times['TSK-003']['worker_id'],times['TSK-021']['worker_id'])
        self.assertGreaterEqual(times['TSK-003']['start_minute'],60-1e-5)
        self.assertGreaterEqual(times['TSK-021']['start_minute'],times['TSK-003']['finish_minute']-1e-5)
        for route in r['routes']:
            self.assertGreaterEqual(route['break']['start_minute'],120-1e-5)
            self.assertLessEqual(route['break']['end_minute'],180+1e-5)

    def test_soft_deadline_reports_lateness(self):
        d=fixture();d['tasks'][0]['deadline_minute']=70
        r=solve(d)
        self.assertEqual(len(r['assignments']),2)
        self.assertGreaterEqual(r['total_late_minutes'],30-1e-5)

    def test_checker_rejects_early_start_and_bad_rest(self):
        d=fixture();r=solve(d)
        broken=copy.deepcopy(r)
        broken['task_schedule'][0]['start_minute']=0
        with self.assertRaises(ValueError):validate_schedule(d,broken)
        broken=copy.deepcopy(r)
        broken['routes'][0]['break']['end_minute']+=1
        with self.assertRaises(ValueError):validate_schedule(d,broken)

    def test_return_and_break_make_late_release_unassignable(self):
        d=fixture();d['tasks'][0]['release_minute']=230
        r=solve(d)
        self.assertEqual(len(r['assignments']),0)
        self.assertEqual(len(r['unassigned']),2)

    def test_balancing_splits_equal_tasks(self):
        d=fixture()
        for w in d['workers']:
            w.update(skills=['cleaning'],tools=['cleaning_kit'],start_location_id='LOC-01',end_location_id='LOC-01')
        for t in d['tasks']:
            t.update(required_skills=['cleaning'],required_tools=['cleaning_kit'],location_id='LOC-01',
                     predecessor_task_ids=[],duration_minutes=30,release_minute=0,deadline_minute=100)
        r=solve(d)
        self.assertEqual(len(r['assignments']),2)
        self.assertEqual(sorted(route['work_minutes'] for route in r['routes']),[30,30])
        self.assertAlmostEqual(r['max_work_utilization'],30/210)

    def test_locked_work_input_rejected(self):
        d=fixture();d['tasks'][0]['locked_worker_id']='WRK-01'
        with self.assertRaises(ValueError):build_model(d)
