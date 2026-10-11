"""Batch assignment with coordinate-derived travel and closed worker routes."""
import argparse
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_b import build_model as build_assignment_model, prepare, validate_assignments
from baselines.stage_a import distance_km


def build_model(data, env=None):
    import gurobipy as gp
    speed=data['assumptions']['travel_speed_kmh']
    if speed<=0: raise ValueError('Speed must be positive')
    m,x,u,p=build_assignment_model(data,env)
    locations={l['id']:l for l in data['locations']}
    arcs=[]; distances={}; worker_tasks={}
    for k,w in p['workers'].items():
        ids=[i for i,wid in p['eligible'] if wid==k]
        worker_tasks[k]=ids
        origin=f'origin:{k}'; end=f'end:{k}'
        pairs=[(origin,i) for i in ids]+[(i,end) for i in ids]+[(i,j) for i in ids for j in ids if i!=j]
        def loc(node):
            if node==origin: return locations[w['start_location_id']]
            if node==end: return locations[w['end_location_id']]
            return locations[p['tasks'][node]['location_id']]
        for i,j in pairs:
            key=(i,j,k);arcs.append(key);distances[key]=distance_km(loc(i),loc(j))
    y=m.addVars(arcs,vtype=gp.GRB.BINARY,name='travel_arc')
    h=m.addVars(list(p['workers']),vtype=gp.GRB.BINARY,name='route_used')
    order=m.addVars(p['eligible'],lb=0,ub=len(p['tasks']),name='route_order')
    for k,ids in worker_tasks.items():
        origin=f'origin:{k}';end=f'end:{k}'
        m.remove(m.getConstrByName(f'capacity_{k}'))
        m.addConstr(gp.quicksum(y[origin,i,k] for i in ids)==h[k])
        m.addConstr(gp.quicksum(y[i,end,k] for i in ids)==h[k])
        m.addConstr(h[k]<=gp.quicksum(x[i,k] for i in ids))
        for i in ids:
            m.addConstr(x[i,k]<=h[k])
            m.addConstr(y[origin,i,k]+gp.quicksum(y[j,i,k] for j in ids if j!=i)==x[i,k])
            m.addConstr(y[i,end,k]+gp.quicksum(y[i,j,k] for j in ids if j!=i)==x[i,k])
            m.addConstr(order[i,k]>=x[i,k])
            m.addConstr(order[i,k]<=len(ids)*x[i,k])
            for j in ids:
                if i==j:continue
                m.addConstr((y[i,j,k]==1)>>(order[j,k]>=order[i,k]+1))
                if i in p['tasks'][j]['predecessor_task_ids']:
                    m.addConstr((x[j,k]==1)>>(order[j,k]>=order[i,k]+1))
        service=gp.quicksum(p['tasks'][i]['duration_minutes']*x[i,k] for i in ids)
        travel=gp.quicksum(distances[a]/speed*60*y[a] for a in arcs if a[2]==k)
        m.addConstr(service+travel<=p['capacities'][k],name=f'capacity_with_travel_{k}')
    m.setObjectiveN(gp.quicksum(distances[a]*y[a] for a in arcs),3,priority=10,
                    abstol=0,reltol=0,name='closed_route_distance_km')
    m.update()
    p.update(arcs=arcs,distances=distances,speed=speed)
    return m,x,u,y,p


def validate_routes(data, routes, assignments):
    """Independently recompute route distances and capacities from input coordinates."""
    p=prepare(data); validate_assignments(p,assignments)
    locations={l['id']:l for l in data['locations']}
    expected={k:set() for k in p['workers']}
    for a in assignments:expected[a['worker_id']].add(a['task_id'])
    seen=set(); totals=[]
    for route in routes:
        k=route['worker_id']
        if k not in expected or k in seen:raise ValueError('Unknown or duplicate worker route')
        seen.add(k);ids=route['task_ids']
        if len(set(ids))!=len(ids) or set(ids)!=expected[k]:raise ValueError('Route does not match assignments')
        pos={i:n for n,i in enumerate(ids)}
        for i in ids:
            for parent in p['tasks'][i]['predecessor_task_ids']:
                if parent in pos and pos[parent]>=pos[i]:raise ValueError('Invalid same-worker prerequisite order')
        w=p['workers'][k]
        nodes=[w['start_location_id']]+[p['tasks'][i]['location_id'] for i in ids]+[w['end_location_id']]
        distance=sum(distance_km(locations[a],locations[b]) for a,b in zip(nodes,nodes[1:])) if ids else 0
        travel=distance/data['assumptions']['travel_speed_kmh']*60
        service=sum(p['tasks'][i]['duration_minutes'] for i in ids)
        if travel+service>p['capacities'][k]+1e-5:raise ValueError('Work plus travel exceeds capacity')
        totals.append(dict(worker_id=k,task_ids=ids,distance_km=distance,travel_minutes=travel,
                           service_minutes=service,work_minutes=service+travel,
                           capacity_minutes=p['capacities'][k],break_minutes=w['break_duration_minutes']))
    if seen!=set(expected):raise ValueError('Missing worker route')
    return totals


def solve(data):
    import gurobipy as gp
    m,x,u,y,p=build_model(data)
    try:
        m.optimize()
        base=dict(stage='B_WITH_TRAVEL',scenario_id=data['scenario_id'],status_code=m.Status,
                  has_solution=m.SolCount>0,runtime_seconds=m.Runtime,speed_kmh=p['speed'],
                  status='OPTIMAL' if m.Status==gp.GRB.OPTIMAL else ('TIME_LIMIT' if m.Status==gp.GRB.TIME_LIMIT else str(m.Status)),
                  distance_method='haversine',travel_formula='distance_km / speed_kmh * 60',
                  notice='含起程、任務串接及回程的估計移動時間，無道路倍率或緩衝；尚未計算開始時間、時窗、跨人員前置等待或休息位置，仍非完整排程。',
                  excluded_tasks=p['excluded'],is_synthetic=True)
        if not m.SolCount:return dict(base,routes=[],assignments=[],message='無可行解，不能套用計畫')
        assignments=[dict(task_id=i,worker_id=k) for i,k in p['eligible'] if x[i,k].X>0.5]
        routes=[]
        for k in p['workers']:
            successors={i:j for i,j,w in p['arcs'] if w==k and y[i,j,w].X>0.5}
            ids=[];node=f'origin:{k}'
            while node in successors:
                node=successors[node]
                if node==f'end:{k}':break
                if node in ids:raise ValueError('Route cycle')
                ids.append(node)
            routes.append(dict(worker_id=k,task_ids=ids))
        routes=validate_routes(data,routes,assignments)
        objective=[]
        for n in range(m.NumObj):
            m.Params.ObjNumber=n
            objective.append(dict(name=m.ObjNName,value=m.ObjNVal))
        return dict(base,assignments=assignments,routes=routes,
                    unassigned=[i for i in p['tasks'] if u[i].X>0.5],
                    objective_values=objective,optimal_status=m.Status==gp.GRB.OPTIMAL,
                    total_distance_km=sum(r['distance_km'] for r in routes),
                    total_travel_minutes=sum(r['travel_minutes'] for r in routes))
    finally:m.dispose()


def report(result):
    lines=['# 加入移動時間的批次派工','',f"速度：{result['speed_kmh']} km/h；時間 = 座標直線公里 ÷ 速度 × 60。", '',result['notice'],'',
           f"Gurobi 狀態：{result['status']}（{'已證明最優（依求解容忍值）' if result['optimal_status'] else '可行解，尚未證明最優'}）；指派 {len(result['assignments'])} 件，未派 {len(result['unassigned'])} 件。",
           f"總路線距離 {result['total_distance_km']:.3f} 公里；估計移動 {result['total_travel_minutes']:.1f} 分鐘。",'',
           '| 人員 | 任務順序 | 處理分鐘 | 移動分鐘 | 合計分鐘 | 上限分鐘 |','|---|---|---|---|---|---|']
    for r in result['routes']:
        lines.append(f"| {r['worker_id']} | {' → '.join(r['task_ids']) or '無任務'} | {r['service_minutes']} | {r['travel_minutes']:.1f} | {r['work_minutes']:.1f} | {r['capacity_minutes']} |")
    lines+=['','每條路線均從該員工起點出發、依序服務後返回。上限已扣 30 分鐘休息，但尚未安排實際休息時段。',
            '同人員前置任務按順序處理；跨人員前置只保證一起指派，等待時間將在 C 排程建模。','']
    return '\n'.join(lines)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input',type=Path,default=ROOT/'data/taipei_base.json')
    parser.add_argument('--output-dir',type=Path,default=ROOT/'output')
    args=parser.parse_args();result=solve(json.loads(args.input.read_text()))
    args.output_dir.mkdir(parents=True,exist_ok=True)
    (args.output_dir/'stage_b_travel.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    if result['has_solution']:
        (args.output_dir/'stage_b_travel_report.md').write_text(report(result))
    print(json.dumps({k:result.get(k) for k in ['has_solution','status_code','total_distance_km','total_travel_minutes']},ensure_ascii=False))
