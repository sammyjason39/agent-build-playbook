#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { isAbsolute, join, resolve } from 'node:path';
import { ROOT } from './workspace.mjs';

const target = process.argv[2] && !process.argv[2].startsWith('-') ? process.argv[2] : '.';
const dir = isAbsolute(target) ? target : resolve(process.cwd(), target);

if (!existsSync(dir) || !statSync(dir).isDirectory()) {
  console.error(`check-tarball: not a directory: ${dir}`);
  process.exit(1);
}
if (!existsSync(join(dir, 'package.json'))) {
  console.error(`check-tarball: no package.json in ${dir}`);
  process.exit(1);
}

const pkg = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'));

const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const result = spawnSync(npm, ['pack', '--dry-run', '--json', '--ignore-scripts'], {
  cwd: dir,
  encoding: 'utf8',
  env: {
    ...process.env,
    npm_config_offline: 'true',
    npm_config_audit: 'false',
    npm_config_fund: 'false',
    npm_config_update_notifier: 'false',
    npm_config_loglevel: 'error',
  },
});

if (result.error) {
  console.error(`check-tarball: failed to run npm pack: ${result.error.message}`);
  process.exit(1);
}
if (result.status !== 0) {
  console.error(`check-tarball: npm pack --dry-run failed (exit ${result.status})`);
  if (result.stderr) console.error(result.stderr.trim());
  process.exit(1);
}

let report;
try {
  report = JSON.parse(result.stdout);
} catch {
  console.error('check-tarball: could not parse npm pack --dry-run --json output');
  console.error(result.stdout);
  process.exit(1);
}

const entry = Array.isArray(report) ? report[0] : report;
if (!entry) {
  console.error('check-tarball: npm pack returned no package entry');
  process.exit(1);
}

const files = Array.isArray(entry.files) ? entry.files : [];
const nodeModules = files.filter((f) => String(f.path).includes('node_modules'));
const tests = files.filter((f) => /\.(test|spec)\.[cm]?[jt]sx?$/.test(String(f.path)));
const fmt = (n) => `${(n / 1024).toFixed(2)} KiB (${n.toLocaleString('en-US')} B)`;

console.log(`check-tarball: ${entry.name}@${entry.version}`);
console.log(`  directory:      ${dir.replace(ROOT + '/', '').replaceAll('\\', '/')}`);
console.log(`  tarball:        ${entry.filename}`);
console.log(`  files:          ${entry.entryCount ?? files.length}`);
console.log(`  packed size:    ${fmt(entry.size ?? 0)}`);
console.log(`  unpacked size:  ${fmt(entry.unpackedSize ?? 0)}`);
console.log(
  `  node_modules:   ${nodeModules.length} entr${nodeModules.length === 1 ? 'y' : 'ies'}`,
);
console.log(`  test files:     ${tests.length}`);

if (entry.entryCount !== undefined && entry.entryCount !== files.length) {
  console.error(
    `check-tarball: file list mismatch (entryCount=${entry.entryCount}, files=${files.length})`,
  );
  process.exit(1);
}
if (nodeModules.length) {
  console.error('check-tarball: node_modules would be published');
  for (const f of nodeModules) console.error(`  - ${f.path}`);
  process.exit(1);
}

if (tests.length) {
  console.error('check-tarball: test files would be published (add them to the "files" exclusions)');
  for (const f of tests.slice(0, 20)) console.error(`  - ${f.path}`);
  process.exit(1);
}

console.log('check-tarball: OK');
