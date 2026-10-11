"""Batch assignment MILP: skills, tools, total service capacity, origin distance."""
import argparse
import json
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from baselines.stage_a import distance_km, recommend


def prepare(data):
    recommend(data)  # Validate IDs, coordinates, locations and prerequisites.
    tasks = {t['id']: t for t in data['tasks']}
    workers = {w['id']: w for w in data['workers']}
    locations = {l['id']: l for l in data['locations']}
    active, excluded = {}, []
    for tid, t in tasks.items():
        if t['status'] != 'PENDING' or t.get('locked_worker_id') or t.get('locked_start_minute') is not None:
            excluded.append({'task_id': tid, 'reason': '非待派或人工鎖定，保留原安排'})
        else:
            if t['duration_minutes'] <= 0:
                raise ValueError('Task duration must be positive')
            active[tid] = t
    capacities = {}
    for wid, w in workers.items():
        cap = w['shift_end_minute']-w['available_from_minute']-w['break_duration_minutes']
        if cap < 0:
            raise ValueError('Invalid worker service capacity')
        capacities[wid] = cap
    eligible, costs = [], {}
    for tid, t in active.items():
        for wid, w in workers.items():
            if set(t['required_skills']) <= set(w['skills']) and set(t['required_tools']) <= set(w['tools']):
                eligible.append((tid, wid))
                costs[tid, wid] = distance_km(locations[w['start_location_id']], locations[t['location_id']])
    return dict(tasks=active, all_tasks=tasks, workers=workers, capacities=capacities,
                eligible=eligible, costs=costs, excluded=excluded)


def build_model(data, env=None):
    import gurobipy as gp
    p = prepare(data)
    m = gp.Model('inspectflow_stage_b', env=env)
    m.Params.OutputFlag = 0
    m.Params.TimeLimit = data.get('solver_defaults', {}).get('time_limit_seconds', 30)
    m.Params.MIPGap = data.get('solver_defaults', {}).get('mip_gap', 0.02)
    x = m.addVars(p['eligible'], vtype=gp.GRB.BINARY, name='assign')
    u = m.addVars(list(p['tasks']), vtype=gp.GRB.BINARY, name='unassigned')
    for tid, t in p['tasks'].items():
        m.addConstr(gp.quicksum(x[i,k] for i,k in p['eligible'] if i==tid)+u[tid]==1, name=f'one_{tid}')
        for parent in t['predecessor_task_ids']:
            if p['all_tasks'][parent]['status'] == 'COMPLETED':
                continue
            if parent in p['tasks']:
                m.addConstr(u[tid]>=u[parent], name=f'pre_{parent}_{tid}')
            else:
                m.addConstr(u[tid]==1, name=f'blocked_{tid}_{parent}')
    for wid, capacity in p['capacities'].items():
        m.addConstr(gp.quicksum(p['tasks'][tid]['duration_minutes']*x[tid,k]
                               for tid,k in p['eligible'] if k==wid)<=capacity, name=f'capacity_{wid}')
    # Four lexicographic objectives: urgent coverage, high coverage, total coverage, distance.
    for index, (name, priority) in enumerate([('urgent_unassigned',40),('high_unassigned',30),('all_unassigned',20)]):
        level = ['urgent','high',None][index]
        expr = gp.quicksum(u[tid] for tid,t in p['tasks'].items() if level is None or t['priority']==level)
        m.setObjectiveN(expr,index,priority=priority,abstol=0,reltol=0,name=name)
    m.setObjectiveN(gp.quicksum(p['costs'][pair]*x[pair] for pair in p['eligible']),3,
                    priority=10,abstol=0,reltol=0,name='origin_distance_km')
    m.ModelSense = gp.GRB.MINIMIZE
    m.update()
    return m, x, u, p


def validate_assignments(p, assignments):
    seen, loads = set(), {wid:0 for wid in p['workers']}
    for row in assignments:
        pair = row['task_id'], row['worker_id']
        if pair not in p['costs'] or pair[0] in seen:
            raise ValueError('Duplicate or incompatible assignment')
        seen.add(pair[0])
        loads[pair[1]] += p['tasks'][pair[0]]['duration_minutes']
    for wid, load in loads.items():
        if load > p['capacities'][wid]:
            raise ValueError('Capacity exceeded')
    for tid in seen:
        for parent in p['tasks'][tid]['predecessor_task_ids']:
            if p['all_tasks'][parent]['status'] != 'COMPLETED' and parent not in seen:
                raise ValueError('Missing prerequisite assignment')
    return loads


def solve(data):
    import gurobipy as gp
    m, x, u, p = build_model(data)
    try:
        m.optimize()
        base = dict(stage='B', scenario_id=data['scenario_id'], solver='Gurobi',
                    status_code=m.Status, runtime_seconds=m.Runtime, has_solution=m.SolCount>0,
                    notice='批次指派建議，不是完整排程。僅計服務工時容量與固定起點直線距離；未計交通工時、時窗、前置完成時間或回程。',
                    excluded_tasks=p['excluded'], is_synthetic=True)
        if not m.SolCount:
            return dict(base, assignments=[], unassigned=[], message='沒有可行解，不能套用計畫')
        assignments = [dict(task_id=tid,worker_id=wid,duration_minutes=p['tasks'][tid]['duration_minutes'],
                            origin_distance_km=round(p['costs'][tid,wid],3))
                       for tid,wid in p['eligible'] if x[tid,wid].X>0.5]
        loads = validate_assignments(p,assignments)
        unassigned=[]
        for tid in p['tasks']:
            if u[tid].X>0.5:
                reason='無合格人員' if not any(i==tid for i,k in p['eligible']) else '容量或前置競爭，需進一步診斷'
                unassigned.append(dict(task_id=tid,reason=reason))
        objectives=[]
        for index in range(m.NumObj):
            m.Params.ObjNumber=index
            objectives.append(dict(name=m.ObjNName,value=m.ObjNVal))
        return dict(base, assignments=assignments,unassigned=unassigned,
                    objective_values=objectives,
                    worker_loads=[dict(worker_id=wid,service_minutes=load,capacity_minutes=p['capacities'][wid]) for wid,load in loads.items()],
                    proven_optimal=m.Status==gp.GRB.OPTIMAL,
                    quality_notice='多目標各階段界限尚未收集；未宣稱單一 MIPGap 能代表全部目標品質。')
    finally:
        m.dispose()


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input',type=Path,default=ROOT/'data/taipei_base.json')
    parser.add_argument('--output',type=Path,default=ROOT/'output/stage_b_assignments.json')
    args=parser.parse_args()
    data=json.loads(args.input.read_text())
    try:
        result=solve(data)
    except ImportError:
        result=dict(stage='B',has_solution=False,status='DEPENDENCY_MISSING',message='請安裝 gurobipy')
    except Exception as exc:
        import gurobipy as gp
        if not isinstance(exc,gp.GurobiError):
            raise
        result=dict(stage='B',has_solution=False,status='GUROBI_ERROR',error_code=exc.errno,
                    message='Gurobi 初始化或求解失敗，請檢查本機授權。此檔不是派工計畫。')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:result[k] for k in ['stage','has_solution']},ensure_ascii=False))
    sys.exit(0 if result['has_solution'] else 2)
