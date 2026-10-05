#!/usr/bin/env node
/**
 * Publish a pnpm monorepo to GitHub Packages under the repository owner's scope
 * (GitHub Packages only accepts npm packages whose scope equals the owning account).
 *
 * Source names stay as they are (e.g. `@acme/shared`, `@acme-modules/crm`); each packed
 * tarball is rewritten at publish time:
 *
 *   @<internal>/<name>  ->  @<SCOPE>/<internal>-<name>
 *
 * and internal dependencies become npm aliases
 * ("@acme/shared": "npm:@<SCOPE>/acme-shared@1.2.3"), so `import '@acme/shared'`
 * inside the published code keeps resolving. Consumers install with the same alias form.
 *
 * Config (env):
 *   PUBLISH_SCOPE            target scope without @ (required; the lower-case owner, e.g. my-org)
 *   PUBLISH_INTERNAL_SCOPES  comma-separated source scopes to rewrite (required, e.g. @acme,@acme-modules)
 *   PUBLISH_REPOSITORY       git URL for package.json "repository" (required by GitHub Packages)
 *   PUBLISH_INCLUDE          comma-separated path prefixes to publish (default packages/,modules/)
 *   PUBLISH_EXCLUDE          comma-separated package names to keep private (e.g. @acme-modules/_example)
 *   PUBLISH_REGISTRY         default https://npm.pkg.github.com
 *   PNPM                     pnpm invocation (default "corepack pnpm")
 *
 * Usage:
 *   node scripts/publish-github.mjs --dry-run       # pack + rewrite only, no registry
 *   NODE_AUTH_TOKEN=... node scripts/publish-github.mjs
 * Idempotent: versions already in the registry are skipped. The token is passed via a
 * temporary npmrc and never written into the repo.
 */
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { listWorkspacePackages } from './workspace.mjs';

function required(name) {
  const value = process.env[name];
  if (!value) {
    console.error(`${name} is required (see the header of this script)`);
    process.exit(1);
  }
  return value;
}
const list = (v) =>
  (v ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

const SCOPE = required('PUBLISH_SCOPE').replace(/^@/, '').toLowerCase();
const INTERNAL = list(required('PUBLISH_INTERNAL_SCOPES')).map((s) => (s.startsWith('@') ? s : `@${s}`));
const REPOSITORY = required('PUBLISH_REPOSITORY');
const REGISTRY = process.env.PUBLISH_REGISTRY ?? 'https://npm.pkg.github.com';
const INCLUDE = list(process.env.PUBLISH_INCLUDE ?? 'packages/,modules/');
const EXCLUDE = new Set(list(process.env.PUBLISH_EXCLUDE));
const PNPM = (process.env.PNPM ?? 'corepack pnpm').split(' ');
const DRY_RUN = process.argv.includes('--dry-run');
const DEP_FIELDS = ['dependencies', 'peerDependencies', 'optionalDependencies'];

export function isInternal(name) {
  return INTERNAL.some((scope) => name.startsWith(`${scope}/`));
}

export function aliasName(name) {
  const scope = INTERNAL.find((sc) => name.startsWith(`${sc}/`));
  if (!scope) throw new Error(`not an internal package: ${name}`);
  return `@${SCOPE}/${scope.slice(1)}-${name.slice(scope.length + 1)}`;
}

function publishable() {
  return listWorkspacePackages().filter(
    ({ rel, pkg }) => INCLUDE.some((prefix) => rel.startsWith(prefix)) && !EXCLUDE.has(pkg.name),
  );
}

/** Topological order over internal runtime dependencies (dependencies first). */
function ordered(packages) {
  const byName = new Map(packages.map((p) => [p.pkg.name, p]));
  const out = [];
  const state = new Map();
  const visit = (p, trail) => {
    const s = state.get(p.pkg.name);
    if (s === 'done') return;
    if (s === 'visiting')
      throw new Error(`dependency cycle: ${[...trail, p.pkg.name].join(' → ')}`);
    state.set(p.pkg.name, 'visiting');
    for (const field of DEP_FIELDS) {
      for (const dep of Object.keys(p.pkg[field] ?? {})) {
        const target = byName.get(dep);
        if (target) visit(target, [...trail, p.pkg.name]);
      }
    }
    state.set(p.pkg.name, 'done');
    out.push(p);
  };
  for (const p of [...packages].sort((a, b) => a.pkg.name.localeCompare(b.pkg.name))) visit(p, []);
  return out;
}

function run(command, args, opts = {}) {
  const result = spawnSync(command, args, { encoding: 'utf8', ...opts });
  if (result.error) throw result.error;
  return result;
}

/** Rewrite a packed manifest for the registry. Exported for tests. */
export function rewriteManifest(manifest, { rel }) {
  const out = { ...manifest };
  out.name = aliasName(manifest.name);
  delete out.private;
  delete out.devDependencies;
  delete out.scripts;
  out.publishConfig = { registry: REGISTRY };
  out.repository = { type: 'git', url: REPOSITORY, directory: rel };
  for (const field of DEP_FIELDS) {
    if (!out[field]) continue;
    const deps = {};
    for (const [dep, range] of Object.entries(out[field])) {
      if (!isInternal(dep)) {
        deps[dep] = range;
        continue;
      }
      if (String(range).startsWith('workspace:')) {
        throw new Error(`${manifest.name}: ${field}.${dep} still "${range}" after pack`);
      }
      deps[dep] = `npm:${aliasName(dep)}@${range}`;
    }
    out[field] = deps;
  }
  return out;
}

function main() {
  const work = mkdtempSync(join(tmpdir(), 'monorepo-publish-'));
  const npmrc = join(work, '.npmrc');
  if (!DRY_RUN) {
    if (!process.env.NODE_AUTH_TOKEN) {
      console.error(
        'NODE_AUTH_TOKEN is required (a token with write:packages), e.g. $(gh auth token)',
      );
      process.exit(1);
    }
    writeFileSync(
      npmrc,
      `@${SCOPE}:registry=${REGISTRY}\n//${new URL(REGISTRY).host}/:_authToken=\${NODE_AUTH_TOKEN}\n`,
      { mode: 0o600 },
    );
  }

  const packages = ordered(publishable());
  console.log(
    `# ${packages.length} packages → ${REGISTRY} as @${SCOPE}/*${DRY_RUN ? ' (dry run)' : ''}`,
  );
  let published = 0;
  let skipped = 0;
  try {
    for (const p of packages) {
      const target = `${aliasName(p.pkg.name)}@${p.pkg.version}`;
      if (!DRY_RUN) {
        const view = run('npm', ['view', target, 'version', '--userconfig', npmrc], { cwd: work });
        if (view.status === 0 && view.stdout.trim() === p.pkg.version) {
          console.log(`skip ${target} (already published)`);
          skipped += 1;
          continue;
        }
      }
      const dest = join(work, p.pkg.name.replace(/[@/]/g, '_'));
      const pack = run(PNPM[0], [...PNPM.slice(1), 'pack', '--pack-destination', dest], { cwd: p.dir });
      if (pack.status !== 0) throw new Error(`pack failed for ${p.rel}:\n${pack.stderr}`);
      const tarball = readdirSync(dest).find((f) => f.endsWith('.tgz'));
      const untar = run('tar', ['-xzf', join(dest, tarball), '-C', dest]);
      if (untar.status !== 0) throw new Error(`untar failed for ${p.rel}`);
      const pkgDir = join(dest, 'package');
      const manifestPath = join(pkgDir, 'package.json');
      const manifest = rewriteManifest(JSON.parse(readFileSync(manifestPath, 'utf8')), p);
      writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
      if (DRY_RUN) {
        console.log(`ok   ${target}`);
        continue;
      }
      const pub = run('npm', ['publish', pkgDir, '--userconfig', npmrc, '--registry', REGISTRY], {
        cwd: work,
        env: process.env,
      });
      if (pub.status !== 0) throw new Error(`publish failed for ${target}:\n${pub.stderr}`);
      console.log(`pub  ${target}`);
      published += 1;
    }
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
  console.log(
    `\npublish-github: ${published} published, ${skipped} skipped${DRY_RUN ? ' (dry run)' : ''}.`,
  );
}

if (process.argv[1] && process.argv[1].endsWith('publish-github.mjs')) {
  try {
    main();
  } catch (error) {
    console.error(String(error instanceof Error ? error.message : error));
    process.exit(1);
  }
}
