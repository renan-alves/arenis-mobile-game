"""Finish the offline candidate run, retrying only boards without an exact proof.

Requires the initial tmp/rebalanced-candidates.json and rebalanced-first-proof.json.
Never treats a search limit as impossibility and never publishes a limited candidate.
Writes tmp/rebalanced-accepted.json plus an authorship manifest for final validation.
"""
import argparse
import json
import subprocess
from pathlib import Path
from rebalance_campaign import create, ROOT

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    args = parser.parse_args()
    pack = json.loads((ROOT/'tmp/rebalanced-candidates.json').read_text(encoding='utf-8'))
    first = json.loads((ROOT/'tmp/rebalanced-first-proof.json').read_text(encoding='utf-8'))
    assert len(pack['levels']) == 150 and len(first['results']) == 150
    levels = {level['id']: level for level in pack['levels']}
    results = {result['id']: result for result in first['results']}
    seeds = {id: 2026111202 for id in levels if not id.startswith('easy-')}
    for round in range(1, 9):
        missing = [id for id, result in results.items() if not result['accepted']]
        if not missing:
            break
        seed = 2026111202 + round * 100000
        print(f'Round {round}: authoring {len(missing)} replacements, seed {seed}', flush=True)
        create(seed, selected_ids=missing)
        candidates = json.loads((ROOT/'tmp/rebalanced-candidates.json').read_text(encoding='utf-8'))
        output = ROOT/f'tmp/rebalanced-retry-{round}.json'
        log = ROOT/f'tmp/rebalanced-retry-{round}.log'
        with log.open('w', encoding='utf-8') as stream:
            run = subprocess.run([args.godot, '--headless', '--log-file', str(ROOT/f'tmp/rebalance-engine-{round}.log'), '--path', str(ROOT), '--script', 'tools/validate_levels.gd', '--', '--input', 'res://tmp/rebalanced-candidates.json', '--solve', '--max-ms', '6000', '--max-states', '60000', '--output', str(output)], stdout=stream, stderr=subprocess.STDOUT)
        assert run.returncode in [0, 1], log.read_text(encoding='utf-8')
        report = json.loads(output.read_text(encoding='utf-8'))
        for result in report['results']:
            if result['accepted']:
                levels[result['id']] = next(level for level in candidates['levels'] if level['id'] == result['id'])
                results[result['id']] = result
                seeds[result['id']] = seed
        print(f'Proven: {sum(r["accepted"] for r in results.values())}/150', flush=True)
    assert all(result['accepted'] for result in results.values()), 'Some candidates still need proof; do not publish.'
    pack['levels'] = list(levels.values())
    for level in pack['levels']:
        level['minimum_moves'] = results[level['id']]['minimum_moves']
    (ROOT/'tmp/rebalanced-accepted.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    manifest = dict(base_seed=2026111202, rules_version=2, authoring='reverse maximum-block moves; solver accepts only exact minima', level_seeds=seeds)
    (ROOT/'docs/relatorios/revisao-desafio-autoria.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('150 boards proven. Run validation again on rebalanced-accepted.json before publication.', flush=True)

if __name__ == '__main__':
    main()
