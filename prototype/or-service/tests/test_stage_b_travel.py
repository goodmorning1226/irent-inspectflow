import itertools
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_b_travel import solve, validate_routes
from optimization.stage_b import prepare
from baselines.stage_a import distance_km
from test_stage_b_solver import tiny

class TravelTest(unittest.TestCase):
    def test_solver_matches_exhaustive_closed_routes(self):
        d=tiny()
        for t in d['tasks']:t['duration_minutes']=25
        for w in d['workers']:w['shift_end_minute']=120
        d['tasks']=d['tasks'][:2]
        p=prepare(d);locs={l['id']:l for l in d['locations']};ids=list(p['tasks'])
        best=None
        for choices in itertools.product([None]+list(p['workers']),repeat=len(ids)):
            groups={k:[i for i,c in zip(ids,choices) if c==k] for k in p['workers']}
            for paths in itertools.product(*(list(itertools.permutations(groups[k])) for k in groups)):
                distance=0;valid=True
                for k,path in zip(groups,paths):
                    w=p['workers'][k]
                    nodes=[w['start_location_id']]+[p['tasks'][i]['location_id'] for i in path]+[w['end_location_id']]
                    km=sum(distance_km(locs[a],locs[b]) for a,b in zip(nodes,nodes[1:])) if path else 0
                    if sum(p['tasks'][i]['duration_minutes'] for i in path)+km/22*60>p['capacities'][k]:valid=False
                    distance+=km
                if valid:
                    key=(sum(c is None for c in choices),distance)
                    if best is None or key<best:best=key
        result=solve(d)
        self.assertTrue(result['has_solution'])
        self.assertTrue(result['optimal_status'])
        self.assertEqual(len(result['unassigned']),best[0])
        self.assertAlmostEqual(result['total_distance_km'],best[1],places=5)
        self.assertAlmostEqual(result['total_travel_minutes'],best[1]/22*60,places=5)

    def test_travel_prevents_service_only_assignment(self):
        d=tiny();d['tasks']=d['tasks'][:1];d['workers']=d['workers'][:1]
        # 60 service minutes exactly fills capacity, but nonzero travel cannot fit.
        r=solve(d)
        self.assertEqual(len(r['assignments']),0)
        self.assertEqual(len(r['unassigned']),1)

    def test_checker_counts_return_trip(self):
        d=tiny();d['tasks']=d['tasks'][:1];d['workers']=d['workers'][:1]
        d['tasks'][0]['duration_minutes']=59
        with self.assertRaises(ValueError):
            validate_routes(d,[dict(worker_id='WRK-01',task_ids=[d['tasks'][0]['id']])],
                            [dict(worker_id='WRK-01',task_id=d['tasks'][0]['id'])])

    def test_zero_distance_same_location(self):
        d=tiny();d['tasks']=d['tasks'][:1];d['workers']=d['workers'][:1]
        d['tasks'][0]['location_id']=d['workers'][0]['start_location_id']
        r=solve(d)
        self.assertEqual(len(r['assignments']),1)
        self.assertEqual(r['total_travel_minutes'],0)
