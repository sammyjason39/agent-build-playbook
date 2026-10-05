---
name: monorepo-release
description: Release a pnpm/TypeScript monorepo's packages — verify tarballs (no tests, no node_modules, every nested package), publish to GitHub Packages under the owner's scope while keeping source package names via npm aliases, run it from a GitHub Actions workflow with GITHUB_TOKEN, tag, and prove a clean install in a fresh consumer project. Use when the user says publish/release/"gas publish", asks how consumers install the packages, or how to set up read:packages access.
---

# Monorepo release (GitHub Packages with scope aliasing)

## 0. Preconditions
- The owner explicitly authorised publishing. Record it as a decision (`K-xx`) in the PRD.
- CI is green on the commit you release.

## 1. Know the registry rule
GitHub Packages (npm) accepts a package only when its **scope equals the owning account**, in lower case. If
the source uses other scopes (`@acme/*`), you can rename everything (invasive) or **alias at publish time**
(recommended):

```
@acme/shared         → @<owner>/acme-shared
@acme-modules/crm    → @<owner>/acme-modules-crm
```

`scripts/publish-github.mjs` does this on the **packed** manifest only. The steps are:
1. `pnpm pack` turns `workspace:*` into exact versions.
2. The manifest gets the new `name`.
3. Internal dependencies become `npm:@<owner>/…@<version>` aliases.
4. `private`, `scripts` and `devDependencies` are removed.
5. `publishConfig.registry` and `repository.directory` are set.

Nothing in the repo is renamed. Configure it through `PUBLISH_*` env vars (see the script header).

## 2. Gate the tarballs
- Copy `scripts/workspace.mjs`, `check-tarball.mjs` and `publish-github.mjs` into the repo's `scripts/`.
- Every publishable package needs a `files` allow-list that excludes tests:
  `"files": ["src", "!src/**/*.test.ts", "!src/**/__tests__/**"]`. **Nested packages** (e.g.
  `packages/sdk/dev-kernel`) need their own list. The reference run's first release failed here.
- Check **every** publishable package in CI, not a hand-picked list.
- Run `node scripts/publish-github.mjs --dry-run` locally. It packs and rewrites all packages and contacts no
  registry.

## 3. Publish from CI (preferred)
- Copy `templates/release.yml` to `.github/workflows/release.yml` and fill in the env.
- Run `gh workflow run release.yml --ref main -f dry_run=false`, then watch it with
  `agent-orchestrator/scripts/ci-watch.sh <run-id>`.
- The workflow `GITHUB_TOKEN` with `packages: write` is enough, so no personal token is needed.
- Local alternative: `NODE_AUTH_TOKEN=$(gh auth token) node scripts/publish-github.mjs`. This needs
  `write:packages`; get it with `gh auth refresh -h github.com -s write:packages`.

## 4. Tag
`git tag -a v<version> <released-sha> -m "…"` and `git push origin v<version>`. Tag only after publishing.

## 5. Prove a clean install (consumer view)
In an empty directory:
```ini
# .npmrc
@<owner>:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}
```
```jsonc
// package.json — consumers keep the source import names
"dependencies": { "@acme/shared": "npm:@<owner>/acme-shared@<v>", "@acme-modules/crm": "npm:@<owner>/acme-modules-crm@<v>", "tsx": "^4" }
```
Install with `NODE_AUTH_TOKEN=$(gh auth token)`, which needs `read:packages`. Then:
- import a contract or manifest through the original names (`tsx check.ts`);
- assert the lockfile has no `workspace:` entries;
- assert no test files were installed.

## 6. Give consumers access
- **Developer machine:** `gh auth refresh -h github.com -s read:packages` (a device code at
  github.com/login/device). If the user asks for "the code", run it in the background and relay the one-time
  code. Never ask them to paste a PAT into the chat.
- **Consumer repo CI:** add `permissions: packages: read`, set `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}`,
  and add the repo under each package's *Package settings → Manage Actions access* (Read).
- **Servers:** a classic PAT with only `read:packages`, stored as a secret env var. Never commit it.
- Packages that ship TypeScript source need `transpilePackages` (Next.js) or a TS loader or bundler on the
  consumer side.

## 7. Document
Update `docs/RELEASE.md` (aliasing table, consumer install, workflow), the CHANGELOG and the PRD decision. Note
the consumer requirements in the integration guide.
