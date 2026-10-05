# agent-build-playbook

Playbook dan skill Claude Code untuk alur kerja yang dipakai saat membangun platform modul 39-modul. Alurnya: beberapa repo
digabung menjadi satu produk modular, dibangun oleh banyak agen opencode yang diorkestrasi Claude Code, sampai
production ready dan ter-publish.

```
            ┌────────────── multi-repo-prd ──────────────┐
repo A ─┐   │ scan (opencode read-only) → brainstorm owner │
repo B ─┼──▶│ → PRD (K-xx) + CONTRACT/DESIGN (LOCKED)      │──▶ prompt pack
repo C ─┘   │ → CATALOG (coverage map) → prompt pack       │    (brief + wave + spec/modul)
            └──────────────────────────────────────────────┘
                                │
            ┌────────────── agent-orchestrator ────────────┐
            │ DAG + ownership + RAM/CPU → MAX_PARALLEL      │
            │ worktree/agent → launch opencode → watch      │◀─┐
            │ review (scope, diff, gate sendiri) → merge     │  │
            │ push → CI hijau                               │  │
            └──────────────────────────────────────────────┘  │
                                │                              │
            ┌──────────── hardening-review-loop ────────────┐  │
            │ checklist produksi → temuan → fix task ───────┼──┘
            │ verifikasi klaim → keputusan owner (K-xx/RFC) │
            └──────────────────────────────────────────────┘
                                │
            ┌────────────── monorepo-release ───────────────┐
            │ gate tarball → publish GitHub Packages (alias)│
            │ via Actions GITHUB_TOKEN → tag → clean install │
            └──────────────────────────────────────────────┘
```

## Skill

| Skill | Kapan dipakai | Isi |
|---|---|---|
| [`multi-repo-prd`](skills/multi-repo-prd/SKILL.md) | "Gabungkan repo-repo ini jadi satu produk modular", "buatkan PRD + oneshot prompt" | `scan.sh` (opencode read-only per repo, di-pin ke SHA), template PRD / MODULE-CONTRACT / DESIGN / CATALOG / common brief / spec modul / RFC / dispatch |
| [`agent-orchestrator`](skills/agent-orchestrator/SKILL.md) | "Orkestrasi opencode", "jalankan paralel / satu per satu", "handover ke opencode" | `new-worktree.sh`, `launch.sh`, `watch.sh`, `resume.sh`, `scope-check.sh`, `ci-watch.sh`, header prompt agen, template task, cara menghitung paralelisme, panduan review dan merge |
| [`hardening-review-loop`](skills/hardening-review-loop/SKILL.md) | "Cek pekerjaan agen", "perbaiki semua sampai production ready" | Checklist produksi (dari bug nyata), prompt untuk agen reviewer read-only, siklus temuan → fix → verifikasi |
| [`monorepo-release`](skills/monorepo-release/SKILL.md) | "Publish", "bagaimana tim platform menginstal", "token read:packages" | `publish-github.mjs` (alias scope), `check-tarball.mjs`, workflow `release.yml`, langkah uji instal bersih |

## Instalasi

**Opsi 1: symlink ke skill personal** (berlaku di semua proyek di mesin ini)
```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/Github/agent-build-playbook
~/Github/agent-build-playbook/install.sh        # menautkan skills/* ke ~/.claude/skills/
```

**Opsi 2: sebagai plugin Claude Code**
```
/plugin marketplace add sammyjason39/agent-build-playbook
/plugin install agent-build-playbook@agent-build-playbook
```

Prasyarat: `git`, `gh` (sudah login), `jq`, `opencode` (sudah login), Node 22 dan pnpm untuk monorepo JS.

## Cara pakai singkat

1. **Rencana.** "Pakai skill multi-repo-prd untuk repo A, B, dan C. Targetnya repo X." Claude men-scan repo
   lewat opencode, menanyakan keputusan penting ke Anda, lalu menulis `docs/` lengkap beserta prompt pack.
2. **Eksekusi.** "Jalankan wave W0 dengan agent-orchestrator." Claude menghitung paralelisme yang aman untuk
   mesin ini, menyiapkan worktree per agen, menjalankan opencode, memantau, me-review, merge, dan memantau CI.
3. **Pengerasan.** "Cek ulang dan perbaiki sampai production ready." Claude menjalankan hardening-review-loop.
4. **Rilis.** "Publish." Claude menjalankan monorepo-release.

## Prinsip yang dibawa dari proyek referensi

- **Keputusan owner dicatat** sebagai `K-xx` dan tidak ditanyakan ulang. Hal yang sudah dikunci hanya berubah
  lewat RFC.
- **Prompt ditulis setelah membaca kode.** Temuan disebut sampai file dan baris, beserta perilaku yang diminta,
  tes, dokumen, dan batas scope.
- **Kepemilikan file eksklusif** per agen, satu worktree per agen, dan `XDG_DATA_HOME` terpisah. Tanpa itu,
  opencode paralel gagal karena SQLite yang sama.
- **Laporan agen hanyalah klaim.** Scope, diff, dan gate dicek sendiri sebelum merge. CI harus hijau sebelum
  pekerjaan dianggap selesai.
- **Server kecil berarti satu agen sekaligus.** Rumus paralelisme ada di
  [`parallelism.md`](skills/agent-orchestrator/references/parallelism.md).
- **Laporan ke owner** memakai bahasa owner, per milestone, dan kegagalan disebut apa adanya.

Proyek referensi (privat): monorepo modular monolith dengan 39 modul, siklus FIX-01 dan PROD-P1…P9, serta rilis
`v0.1.0` ke GitHub Packages.
