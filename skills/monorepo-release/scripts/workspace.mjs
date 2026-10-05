import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function isDir(p) {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function readJson(p) {
  return JSON.parse(readFileSync(p, 'utf8'));
}

export function workspacePatterns() {
  const file = join(ROOT, 'pnpm-workspace.yaml');
  if (!existsSync(file)) return ['packages/*', 'modules/*', 'apps/*', 'tools/*'];
  const text = readFileSync(file, 'utf8');
  const patterns = [];
  let inList = false;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.replace(/#.*$/, '');
    if (/^\s*packages\s*:/.test(line)) {
      inList = true;
      continue;
    }
    if (!inList) continue;
    const m = line.match(/^\s*-\s*['"]?([^'"]+?)['"]?\s*$/);
    if (m) {
      patterns.push(m[1]);
    } else if (/^\S/.test(line)) {
      inList = false;
    }
  }
  return patterns;
}

function expand(pattern) {
  const segments = pattern.split('/').filter(Boolean);
  let dirs = [ROOT];
  for (const seg of segments) {
    const next = [];
    for (const d of dirs) {
      if (!isDir(d)) continue;
      if (seg === '*') {
        for (const entry of readdirSync(d)) {
          const p = join(d, entry);
          if (isDir(p)) next.push(p);
        }
      } else if (seg.includes('*')) {
        const re = new RegExp(
          '^' + seg.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]*') + '$',
        );
        for (const entry of readdirSync(d)) {
          const p = join(d, entry);
          if (re.test(entry) && isDir(p)) next.push(p);
        }
      } else {
        next.push(join(d, seg));
      }
    }
    dirs = next;
  }
  return dirs;
}

export function listWorkspacePackages() {
  const seen = new Set();
  const out = [];
  for (const pattern of workspacePatterns()) {
    for (const dir of expand(pattern)) {
      if (!existsSync(join(dir, 'package.json'))) continue;
      if (seen.has(dir)) continue;
      seen.add(dir);
      out.push({
        dir,
        rel: relative(ROOT, dir).replaceAll('\\', '/'),
        pkg: readJson(join(dir, 'package.json')),
      });
    }
  }
  out.sort((a, b) => a.rel.localeCompare(b.rel));
  return out;
}

export function isModuleDir(rel) {
  return rel.startsWith('modules/');
}
