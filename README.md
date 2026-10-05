# agent-build-playbook

Playbook dan skill Claude Code untuk membangun produk modular dengan banyak agen opencode yang diorkestrasi
Claude Code, sampai production ready dan ter-publish. Ada dua titik awal:

- **Beberapa repo → satu produk modular baru** (`multi-repo-prd`). Alur ini dipakai saat membangun platform
  39 modul.
- **Satu repo besar yang terlalu kompleks → modular di tempat** (`modularize-monolith`). Aplikasi tetap jalan
  di setiap langkah.

```
            ┌────────────── multi-repo-prd ──────────────┐
repo A ─┐   │ scan (opencode read-only) → brainstorm owner │
repo B ─┼──▶│ → PRD (K-xx) + CONTRACT/DESIGN (LOCKED)      │──▶ prompt pack
repo C ─┘   │ → CATALOG (coverage map) → prompt pack       │    (brief + wave + spec/modul)
            └──────────────────────────────────────────────┘
                     atau
            ┌──────────── modularize-monolith ─────────────┐
satu repo ─▶│ coupling (import, tabel, co-change) → peta   │──▶ rencana M0..M4
besar       │ modul → characterization test + ratchet      │    + task ekstraksi kecil
            │ → ekstraksi leaf-first, selalu bisa rilis    │
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
| [`modularize-monolith`](skills/modularize-monolith/SKILL.md) | "Repo ini terlalu kompleks, buat jadi modular", "pecah god service", "siapkan untuk microservice nanti" | `coupling-report.sh` (hotspot, churn, co-change dari git untuk bahasa apa pun), `scan-monolith.sh` (scan arsitektur opencode read-only), `ratchet.sh` (pelanggaran batas hanya boleh berkurang), playbook strangler, pemisahan DB tanpa downtime, template rencana dan task ekstraksi |
| [`agent-orchestrator`](skills/agent-orchestrator/SKILL.md) | "Orkestrasi opencode", "jalankan paralel / satu per satu", "handover ke opencode" | `new-worktree.sh`, `launch.sh`, `watch.sh`, `resume.sh`, `scope-check.sh`, `ci-watch.sh`, header prompt agen, template task, cara menghitung paralelisme, panduan review dan merge |
| [`hardening-review-loop`](skills/hardening-review-loop/SKILL.md) | "Cek pekerjaan agen", "perbaiki semua sampai production ready" | Checklist produksi (dari bug nyata), prompt untuk agen reviewer read-only, siklus temuan → fix → verifikasi |
| [`monorepo-release`](skills/monorepo-release/SKILL.md) | "Publish", "bagaimana tim platform menginstal", "token read:packages" | `publish-github.mjs` (alias scope), `check-tarball.mjs`, workflow `release.yml`, langkah uji instal bersih |

## Instalasi

Semua skill memakai format standar **Agent Skills** (folder berisi `SKILL.md` dengan frontmatter `name` dan
`description`, plus `scripts/`, `templates/`, `references/`). Format ini dibaca oleh Claude Code, opencode,
Hermes, dan Antigravity. Bedanya hanya di folder tempat skill dicari.

**Prasyarat umum:** `git`, `gh` (sudah login), `jq`, dan `opencode` (sudah login) sebagai eksekutor agen. Untuk
monorepo JS juga perlu Node 22 dan pnpm. Script memakai bash, jadi di Windows jalankan lewat WSL.

### Cara tercepat (semua tool sekaligus)

```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/Github/agent-build-playbook
cd ~/Github/agent-build-playbook
./install.sh all          # atau pilih: ./install.sh claude opencode hermes antigravity antigravity-cli
```

`install.sh` membuat **symlink**, jadi cukup `git pull` untuk memperbarui semua tool sekaligus. Folder asli
dengan nama yang sama tidak akan ditimpa. Kalau sebuah tool atau sandbox tidak mengikuti symlink, pakai
`SKILLS_COPY=1 ./install.sh <target>` untuk menyalin file (setelah `git pull`, jalankan ulang).

| Target `install.sh` | Lokasi global | Dipakai oleh |
|---|---|---|
| `claude` | `~/.claude/skills/<skill>` | Claude Code (opencode juga membaca folder ini) |
| `opencode` | `~/.config/opencode/skills/<skill>` | opencode |
| `agents` | `~/.agents/skills/<skill>` | opencode dan tool lain yang membaca `.agents/skills` |
| `antigravity` | `~/.gemini/config/skills/<skill>` | Antigravity IDE |
| `antigravity-cli` | `~/.gemini/antigravity-cli/skills/<skill>` | Antigravity CLI (`agy`) |
| `hermes` | `~/.hermes/skills/agent-build-playbook/` | Hermes Agent (satu kategori berisi semua skill) |

### Claude Code

**Opsi A: plugin** (paling mudah, tanpa clone)
```
/plugin marketplace add sammyjason39/agent-build-playbook
/plugin install agent-build-playbook@agent-build-playbook
```
Untuk update: `/plugin marketplace update agent-build-playbook`.

**Opsi B: skill personal** lewat `./install.sh claude`. Skill tersedia di semua proyek.

**Opsi C: per proyek.** Salin atau symlink `skills/*` ke `<repo>/.claude/skills/` lalu commit, supaya seluruh
tim mendapatkannya.

Cek di Claude Code: ketik `/` lalu cari `agent-orchestrator`. Bisa juga langsung bilang "pakai skill
agent-orchestrator".

### opencode

opencode mencari skill di `~/.config/opencode/skills/`, `~/.claude/skills/`, dan `~/.agents/skills/` (global),
serta di `.opencode/skills/`, `.claude/skills/`, dan `.agents/skills/` di proyek. Jadi:

```sh
./install.sh opencode     # atau: ./install.sh claude  (opencode ikut membacanya)
opencode debug skill | grep -E '"name": "(multi-repo-prd|modularize-monolith|agent-orchestrator|hardening-review-loop|monorepo-release)"'
```

Untuk per proyek: `mkdir -p .opencode/skills && ln -s ~/Github/agent-build-playbook/skills/* .opencode/skills/`.

### Hermes Agent

**Opsi A: tap GitHub** (registry Hermes, tanpa clone)
```sh
hermes skills tap add sammyjason39/agent-build-playbook
hermes skills install sammyjason39/agent-build-playbook/multi-repo-prd
hermes skills install sammyjason39/agent-build-playbook/modularize-monolith
hermes skills install sammyjason39/agent-build-playbook/agent-orchestrator
hermes skills install sammyjason39/agent-build-playbook/hardening-review-loop
hermes skills install sammyjason39/agent-build-playbook/monorepo-release
hermes skills list | grep -E "multi-repo-prd|modularize-monolith|agent-orchestrator|hardening-review-loop|monorepo-release"
```
Lihat isi skill sebelum memasang dengan `hermes skills inspect sammyjason39/agent-build-playbook/<skill>`.
Untuk update: `hermes skills check` lalu `hermes skills update`.

**Opsi B: folder eksternal** (direkomendasikan kalau Anda juga mengedit skill). Setelah clone, tambahkan ke
`~/.hermes/config.yaml`:
```yaml
skills:
  external_dirs:
    - ~/Github/agent-build-playbook/skills
```
Bisa juga dengan `./install.sh hermes`, yang membuat kategori `~/.hermes/skills/agent-build-playbook` → `skills/`.

**Per proyek:** taruh di `<repo>/.agents/skills/` atau `<repo>/.hermes/skills/`, lalu jalankan `hermes skills trust`
di repo itu. Hermes hanya memuat skill proyek dari repo yang sudah di-trust.

### Antigravity (IDE dan CLI `agy`)

IDE dan CLI memakai folder global yang **berbeda**:

```sh
./install.sh antigravity        # IDE: ~/.gemini/config/skills/  (lokasi lama ~/.gemini/antigravity/skills/ juga dibaca)
./install.sh antigravity-cli    # CLI agy: ~/.gemini/antigravity-cli/skills/
```

Untuk per proyek, keduanya membaca `<workspace>/.agents/skills/<skill>/`:
```sh
mkdir -p .agents/skills && cp -R ~/Github/agent-build-playbook/skills/* .agents/skills/
```
Folder skill proyek menimpa skill global dengan nama yang sama. Muat ulang workspace atau mulai sesi `agy`
baru setelah memasang.

### Catatan kompatibilitas

- Skill ditulis dengan **Claude Code sebagai koordinator** dan **opencode sebagai eksekutor**. Di Hermes atau
  Antigravity, perannya sama: agen yang Anda ajak bicara menjadi koordinator, sedangkan script tetap menjalankan
  `opencode run` di worktree terpisah.
- Fitur khusus Claude Code (Monitor, shell background) punya padanannya di tool lain:
  - jalankan `launch.sh` di background (`nohup … &` atau tab terminal lain);
  - pantau dengan `watch.sh`, yang mencetak satu baris per commit, `STALL`, dan `FINISHED`;
  - untuk CI pakai `ci-watch.sh`.
- Script mencari konfigurasi lewat `ORCH_ROOT`. Jalankan `export ORCH_ROOT=~/Github/<repo>-wt/_orchestration`
  sebelum memakai `agent-orchestrator` (lihat `skills/agent-orchestrator/references/opencode.md`).

## Cara pakai singkat

1. **Rencana.** Pilih salah satu:
   - "Pakai skill multi-repo-prd untuk repo A, B, dan C. Targetnya repo X." Claude men-scan repo lewat opencode,
     menanyakan keputusan penting ke Anda, lalu menulis `docs/` lengkap beserta prompt pack.
   - "Repo ini terlalu kompleks, pakai modularize-monolith." Claude mengukur kopling, mengusulkan peta modul,
     lalu menulis `MODULARIZATION-PLAN.md`, characterization test, ratchet, dan task ekstraksi per gelombang.
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
