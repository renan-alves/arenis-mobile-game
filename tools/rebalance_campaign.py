"""Author a larger unpublished campaign; every minimum still needs Godot proof.

Keeps Easy boards and IDs. Replaces Medium/Hard with explicit board revision 2.
Writes tmp/rebalanced-candidates.json, never overwrites the shipped campaign.
"""
import argparse
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COLORS = ['coral', 'aqua', 'gold', 'lilac', 'sky', 'sage', 'rose', 'peach', 'indigo', 'mint']

def runs(board):
    return sum(1 + sum(a != b for a, b in zip(row, row[1:])) for row in board if row)

def scramble(rng, capacity, count, target_runs):
    board = [[color] * capacity for color in COLORS[:count]] + [[], []]
    visited = {tuple(map(tuple, board))}
    for _ in range(target_runs * 5):
        choices = []
        before = runs(board)
        for source, row in enumerate(board):
            if not row:
                continue
            run = 1
            while run < len(row) and row[-run-1] == row[-1]:
                run += 1
            for target, other in enumerate(board):
                if target == source or len(other) == capacity:
                    continue
                for amount in range(1, min(run, capacity-len(other))+1):
                    new = [r[:] for r in board]
                    new[source] = row[:-amount]
                    new[target] = other + [row[-1]] * amount
                    new_run = amount
                    for color in reversed(other):
                        if color != row[-1]:
                            break
                        new_run += 1
                    # Reversing this step must obey the maximum-block rule.
                    if min(new_run, capacity-len(new[source])) != amount:
                        continue
                    key = tuple(map(tuple, new))
                    if key in visited:
                        continue
                    delta = runs(new) - before
                    choices.append((new, key, 12 if delta > 0 else 1 if delta == 0 else .03))
        if not choices:
            break
        board, key, _ = rng.choices(choices, weights=[c[2] for c in choices])[0]
        visited.add(key)
        if runs(board) >= target_runs:
            return board
    return board

def create(seed=2026111202, sample=False, selected_ids=None):
    old = json.loads((ROOT/'data/campaign.json').read_text(encoding='utf-8-sig'))
    levels = [l for l in old['levels'] if l['difficulty_id'] == 'easy'] if not selected_ids else []
    seen = set()
    for difficulty, capacity, label in [('medium', 5, 'Intermediário'), ('hard', 7, 'Difícil')]:
        for number in range(1, 51):
            if selected_ids and f'{difficulty}-{number:03}' not in selected_ids:
                continue
            if sample and number not in [1, 11, 21, 36, 50]:
                continue
            rng = random.Random(seed + (10000 if difficulty == 'hard' else 0) + number)
            tubes = (7 if number <= 25 else 8) if difficulty == 'medium' else (10 if number <= 15 else 11 if number <= 35 else 12)
            locked = number >= 21
            hidden = 11 <= number <= 20 or number >= 36
            base_colors = tubes - 2 - int(locked)
            lower_bound = (12 + (number-1)//10) if difficulty == 'medium' else (20 + (number-1)//5)
            for attempt in range(1000):
                board = scramble(rng, capacity, base_colors, base_colors + lower_bound)
                if runs(board) - base_colors < lower_bound:
                    continue
                bottles = [{'colors': row} for row in board]
                if locked:
                    partial = [i for i, row in enumerate(board) if 0 < len(row) < capacity]
                    mixed = [i for i, row in enumerate(board) if len(set(row)) > 1]
                    choices = [(a, b) for a in partial for b in mixed if a != b]
                    if not choices:
                        continue
                    origin, target = rng.choice(choices)
                    key = COLORS[base_colors]
                    bottles[origin]['colors'].append(key)
                    bottles[target]['unlock_color'] = key
                    bottles.append({'colors': [key] * (capacity-1)})
                fingerprint = tuple(sorted(tuple(b['colors']) for b in bottles))
                if fingerprint in seen:
                    continue
                if hidden:
                    for bottle in bottles:
                        indices = [i for i in range(len(bottle['colors'])-1) if rng.random() < .6]
                        if indices:
                            bottle['hidden'] = indices
                seen.add(fingerprint)
                break
            else:
                raise RuntimeError(f'Cannot author {difficulty}-{number}')
            lesson = 'Qualquer tubo destrancado com espaço recebe o bloco da cor do topo, até o limite disponível.'
            if hidden:
                lesson += ' As camadas neutras são reveladas ao chegar ao topo.'
            if locked:
                lesson += ' Complete a cor indicada para abrir a tranca.'
            old_level = next(l for l in old['levels'] if l['id'] == f'{difficulty}-{number:03}')
            levels.append(dict(id=old_level['id'], version=int(old_level['version'])+1, title=f'Nível {number}', difficulty=label, difficulty_id=difficulty, capacity=capacity, minimum_moves=0, lesson=lesson, bottles=bottles))
    pack = dict(schema_version=2, rules_version=2, pack_id='campaign', pack_version=int(old['pack_version'])+1, levels=levels)
    (ROOT/'tmp').mkdir(exist_ok=True)
    output = ROOT/'tmp/rebalanced-candidates.json'
    output.write_text(json.dumps(pack, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(f'{len(levels)} candidates: {output}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seed', type=int, default=2026111202)
    parser.add_argument('--sample', action='store_true')
    parser.add_argument('--ids', help='Comma-separated IDs for authoring retries')
    args = parser.parse_args()
    create(args.seed, args.sample, args.ids.split(',') if args.ids else None)
