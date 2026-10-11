"""Licensed integration tests against exhaustive enumeration of tiny instances."""
import copy
import itertools
import json
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_b import prepare, solve


def tiny():
    d=json.loads((ROOT/'data/taipei_base.json').read_text())
    d['workers']=d['workers'][:2]
    for w in d['workers']:
        w['shift_end_minute']=90
    d['tasks']=d['tasks'][1:4]
    for t in d['tasks']:
        t.update(type='cleaning', required_skills=['cleaning'],required_tools=['cleaning_kit'],
                 duration_minutes=60,predecessor_task_ids=[],priority='normal')
    d['solver_defaults']['mip_gap']=0
    return d


def exhaustive(d):
    p=prepare(d)
    tids=list(p['tasks'])
    options=[[None]+[k for i,k in p['eligible'] if i==tid] for tid in tids]
    best=None
    for choices in itertools.product(*options):
        selected=dict(zip(tids,choices))
        loads={k:0 for k in p['workers']}
        for tid,k in selected.items():
            if k is not None: loads[k]+=p['tasks'][tid]['duration_minutes']
        if any(loads[k]>p['capacities'][k] for k in loads): continue
        if any(k is not None and any(selected.get(parent) is None for parent in p['tasks'][tid]['predecessor_task_ids'])
               for tid,k in selected.items()): continue
        unassigned=[tid for tid,k in selected.items() if k is None]
        key=(sum(p['tasks'][i]['priority']=='urgent' for i in unassigned),
             sum(p['tasks'][i]['priority']=='high' for i in unassigned),len(unassigned),
             sum(p['costs'][tid,k] for tid,k in selected.items() if k is not None))
        if best is None or key<best: best=key
    return best

class SolverTest(unittest.TestCase):
    def check_exact(self,d):
        expected=exhaustive(d)
        result=solve(d)
        self.assertTrue(result['has_solution'])
        self.assertTrue(result['proven_optimal'])
        actual=[o['value'] for o in result['objective_values']]
        for a,b in zip(actual,expected): self.assertAlmostEqual(a,b,places=6)
        return result

    def test_capacity_and_distance_match_enumeration(self):
        result=self.check_exact(tiny())
        self.assertEqual(len(result['assignments']),2)
        self.assertEqual(len(result['unassigned']),1)

    def test_urgent_coverage_before_distance(self):
        d=tiny()
        d['tasks'][0]['priority']='urgent'
        d['tasks'][1]['priority']='high'
        result=self.check_exact(d)
        self.assertEqual({r['task_id'] for r in result['assignments']},
                         {d['tasks'][0]['id'],d['tasks'][1]['id']})

    def test_missing_skills_is_unassigned(self):
        d=tiny()
        d['tasks'][0]['required_skills']=['repair']
        self.check_exact(d)

    def test_dependency_not_assigned_alone(self):
        d=tiny()
        d['tasks'][0]['required_skills']=['repair']
        d['tasks'][1]['predecessor_task_ids']=[d['tasks'][0]['id']]
        result=self.check_exact(d)
        self.assertEqual(len(result['assignments']),1)
