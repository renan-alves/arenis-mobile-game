"""Deterministic offline authorship. Godot still has to prove every minimum.
Run from repository root; writes candidate boards with minimum_moves=0.
"""
import itertools
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COLORS = ['coral', 'aqua', 'gold', 'lilac']

def canonical(bottles):
    # Ignore secrets/locks as well: no recycled color layout disguised by an obstacle.
    used = sorted({c for b in bottles for c in b['colors']})
    return min(tuple(sorted(tuple(dict(zip(used, p))[c] for c in b['colors']) for b in bottles))
               for p in itertools.permutations(range(len(used))))

def reverse_board(rng, capacity, count, steps):
    board = [[c]*capacity for c in COLORS[:count]] + [[]]
    seen = set()
    for _ in range(steps):
        choices = []
        for a, source in enumerate(board):
            if not source: continue
            run = 1
            while run < len(source) and source[-run-1] == source[-1]: run += 1
            for b, target in enumerate(board):
                if a == b: continue
                for amount in range(1, min(run, capacity-len(target))+1):
                    new = [row[:] for row in board]
                    color = source[-1]
                    new[a] = source[:-amount]
                    new[b] = target + [color]*amount
                    if new[a] and new[a][-1] != color: continue
                    # Exact forward inverse must be a legal maximum-block pour.
                    target_run = amount
                    for c in reversed(target):
                        if c != color: break
                        target_run += 1
                    if min(target_run, capacity-len(new[a])) != amount: continue
                    key = tuple(map(tuple, new))
                    if key in seen: continue
                    boundaries = sum(sum(x != y for x,y in zip(row,row[1:])) for row in new)
                    choices.append((new, key, 1+boundaries))
        if not choices: break
        new, key, _ = rng.choices(choices, weights=[x[2] for x in choices])[0]
        board = new; seen.add(key)
    return [{'colors': row} for row in board]

def create():
    rng = random.Random(20261112)
    levels = []
    for difficulty, capacity, label in [('easy',3,'Fácil'),('medium',5,'Intermediário'),('hard',7,'Difícil')]:
        seen = set()
        for number in range(1,51):
            hidden = 11 <= number <= 20 or number >= 36
            locked = number >= 21
            for attempt in range(20000):
                count = 2 if (locked and number <= 23) or number <= 3 else 3
                steps = 6 + (number%10)*2 + (0 if difficulty=='easy' else 6)
                bottles = reverse_board(rng,capacity,count,steps)
                boundaries = sum(sum(a!=b for a,b in zip(x['colors'],x['colors'][1:])) for x in bottles)
                if boundaries < (1 if number <= 3 else 2): continue
                if locked:
                    sources = [i for i,b in enumerate(bottles) if 0 < len(b['colors']) < capacity]
                    if not sources: continue
                    origin = rng.choice(sources)
                    targets = [i for i,b in enumerate(bottles) if i!=origin and len(set(b['colors'])) > 1]
                    if not targets: continue
                    key_color = COLORS[count]
                    bottles[origin]['colors'].append(key_color)
                    bottles[rng.choice(targets)]['unlock_color'] = key_color
                    bottles.append({'colors':[key_color]*(capacity-1)})
                if number % 3 != 0 and all(b['colors'] for b in bottles):
                    bottles.append({'colors': []})
                key = canonical(bottles)
                if key in seen: continue
                if number <= 3 and not any(not b['colors'] for b in bottles): continue
                if hidden:
                    for b in bottles:
                        indices = [i for i in range(max(0,len(b['colors'])-1)) if rng.random()<.65]
                        if indices: b['hidden'] = indices
                    # At least one genuinely covered run, not just a top homogeneous block.
                    if not any(any(b['colors'][i]!=b['colors'][-1] for i in b.get('hidden',[])) for b in bottles): continue
                seen.add(key)
                break
            else:
                raise RuntimeError(f'Could not author {difficulty} {number}')
            lesson = 'Toque na origem e depois no destino. Cada despejo conta uma jogada.'
            if hidden: lesson = 'As camadas neutras escondem cores. Elas são reveladas quando chegam ao topo.'
            if locked: lesson = 'Complete a cor indicada na tranca em outro tubo para desbloqueá-la.'
            if hidden and locked: lesson = 'Combine a descoberta das camadas neutras com o desbloqueio dos tubos.'
            levels.append(dict(id=f'{difficulty}-{number:03}',version=1,title=f'Nível {number}',difficulty=label,difficulty_id=difficulty,capacity=capacity,minimum_moves=0,lesson=lesson,bottles=bottles))
    pack=dict(schema_version=2,rules_version=2,pack_id='campaign',pack_version=1,levels=levels)
    (ROOT/'tmp').mkdir(exist_ok=True)
    (ROOT/'tmp/campaign-candidates.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('150 unique candidate boards authored; minima still require Godot proof.')

if __name__=='__main__': create()
