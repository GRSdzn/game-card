import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync, cpSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative, sep } from 'node:path';
const binary = process.env.GODOT_BIN || 'godot';
const suites = {
  boot: [['--editor', '--quit'], ['--quit-after', '8']],
  regression: [
    ['res://tests/battle_smoke_test.tscn', 'Battle smoke tests passed.'],
    ['res://tests/battle_table_ui_test.tscn', 'Battle table UI test passed.'],
    ['res://tests/localization_test.tscn', 'Localization tests passed.'],
  ],
  gameplay: [['res://tests/demo_battle_test.tscn', 'Demo battle tests passed.']],
  ui: [['res://tests/demo_ui_test.tscn', 'Demo UI tests passed.']],
  animation: [['res://tests/instrument_feedback_test.tscn', 'Instrument feedback tests passed.']],
  enemy_animation: [['res://tests/enemy_turn_feedback_test.tscn', 'Enemy turn feedback tests passed.']],
  machine: [['res://tests/machine_test.tscn', 'Machine tests passed.']],
  machine_ui: [['res://tests/machine_ui_test.tscn', 'Machine UI tests passed.']],
};
const suite = process.argv[2];
if (!(suite in suites)) throw new Error(`Expected suite: ${Object.keys(suites).join(', ')}`);
let projectPath = '.';
if (suite === 'boot') {
  // An isolated copy verifies class registration and imports without touching
  // the developer's running editor or relying on an existing .godot cache.
  projectPath = mkdtempSync(join(tmpdir(), 'iron-covenant-boot-'));
  const root = process.cwd();
  cpSync(root, projectPath, { recursive: true, filter: source => {
    const parts = relative(root, source).split(sep);
    return !['.godot', '.git', '.idea'].includes(parts[0]);
  }});
  console.log(`Clean import project: ${projectPath}`);
}
if (suite === 'gameplay') {
  const forbidden = /(?:RunState\.(?:rng|roll_int)|\b(?:randi|randf|randi_range|randf_range)\s*\(|EffectResolver\.resolve)/;
  if (!forbidden.test('RunState.rng.randi()')) throw new Error('RNG scanner positive control failed');
  for (const dir of ['scripts/ui']) for (const name of readdirSync(dir)) {
    if (name.endsWith('.gd') && forbidden.test(readFileSync(`${dir}/${name}`, 'utf8'))) throw new Error(`Gameplay effects/RNG in presentation: ${name}`);
  }
}
const hasErrors = output => /(?:SCRIPT ERROR:|ERROR:|Parse Error|Failed loading resource|WARNING:.*(?:leaked|still in use))/i.test(output);
if (!hasErrors('SCRIPT ERROR: positive control') || hasErrors('normal output')) throw new Error('Diagnostic checker failed');
for (const entry of suites[suite]) {
  const args = ['--headless', '--path', projectPath];
  let token;
  if (entry[0].startsWith('res:')) { args.push(entry[0]); token = entry[1]; }
  else args.push(...entry);
  const result = spawnSync(binary, args, { encoding: 'utf8', windowsHide: true, timeout: 90000, maxBuffer: 1024 * 1024 });
  const output = (result.stdout || '') + (result.stderr || '');
  if (result.error || result.status !== 0 || hasErrors(output) || (token && !output.includes(token))) {
    process.stderr.write(output);
    throw result.error || new Error(`Godot check failed: ${args.join(' ')} (exit ${result.status})`);
  }
  process.stdout.write(`Verified ${entry[0]}\n`);
}
console.log(`${suite.toUpperCase()} verification passed`);
