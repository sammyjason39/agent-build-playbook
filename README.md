# agent-build-playbook

Playbook dan skill Claude Code untuk membangun produk modular dengan banyak agen opencode yang diorkestrasi
Claude Code, sampai production ready dan ter-publish. Ada dua titik awal:

- **Beberapa repo → satu produk modular baru** (`multi-repo-prd`). Alur ini dipakai saat membangun platform
  39 modul.
- **Satu repo besar yang terlalu kompleks → modular di tempat** (`modularize-monolith`). Aplikasi tetap jalan
  di setiap langkah.

**Isi:** [Skill](#skill) · [Pilih skill](#pilih-skill-yang-mana) · [Fitur lengkap](#fitur-lengkap) ·
[Use case](#use-case) · [Instalasi](#instalasi) · [Contoh prompt](#contoh-prompt) ·
[Prinsip](#prinsip-yang-dibawa-dari-proyek-referensi)

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

### Pilih skill yang mana?

| Kondisi Anda | Mulai dari | Lanjut ke |
|---|---|---|
| Punya **beberapa repo** (produk lama, prototipe, repo tim berbeda) dan ingin satu produk modular baru | `multi-repo-prd` | `agent-orchestrator` → `hardening-review-loop` → `monorepo-release` |
| Punya **satu repo besar** yang kusut (god service, tabel dipakai banyak fitur, sulit diubah) | `modularize-monolith` | `agent-orchestrator` → `hardening-review-loop` |
| Sudah punya **rencana atau prompt pack** dan tinggal mendelegasikan ke agen | `agent-orchestrator` | `hardening-review-loop` |
| Agen (opencode atau lainnya) **sudah selesai mengerjakan** sesuatu, dan Anda ragu kualitasnya | `hardening-review-loop` | `agent-orchestrator` untuk fix-nya |
| Monorepo sudah jadi dan perlu **dirilis atau dikonsumsi tim lain** | `monorepo-release` | — |

## Fitur lengkap

### `multi-repo-prd`: beberapa repo → rencana produk modular + prompt pack
- **Scan mendalam per repo oleh agen opencode read-only.** Agen bekerja di worktree sekali pakai yang di-pin ke
  SHA, jadi repo asli tidak tersentuh. Laporannya mencakup stack, tenancy dan auth, inventaris domain (path, tabel,
  route, UI, job, tes, kematangan), model data (termasuk float dan timestamp naif), integrasi, fitur AI, pola yang
  layak dipakai ulang, utang teknis, dan pertanyaan untuk owner. Setiap klaim menyebut path.
- **Brainstorm keputusan dengan owner.** Paling banyak 4 pertanyaan sekali tanya, masing-masing dengan rekomendasi.
  Setiap jawaban langsung dicatat sebagai `K-xx` dan tidak ditanyakan ulang.
- **Dokumen perencanaan lengkap:**
  - `PRD.md`: keputusan terkunci, analisis sumber dengan SHA, wave, dan Definition of Done.
  - `MODULE-CONTRACT.md`: ADR `A-xx` yang dikunci.
  - `DESIGN.md`: token disalin dari UI acuan, plus archetype halaman.
  - `CATALOG.md`: daftar modul, tabel dependensi, dan coverage map yang memastikan setiap fitur sumber punya
    rumah atau alasan dibuang.
  - Dokumen pendukung: `ORCHESTRATION-PLAN.md`, `AGENTS.md`, dan proses RFC.
- **Prompt pack one-shot:**
  - common brief: sumber yang di-pin, aturan keras, dan prosedur 11 langkah;
  - brief per wave (W0 kontrak, W1 fan-out, W2 integrasi, W3 rilis);
  - spec per modul (Keep/Generalise/Drop, kontrak, event, tool AI, acceptance yang bisa dites);
  - tabel dispatch dengan jumlah agen paralel.
- **Pemeriksaan kualitas:** konsistensi jumlah dan key modul di semua dokumen, kepemilikan file eksklusif, dan
  stub kontrak supaya semua modul bisa dikerjakan paralel.

### `modularize-monolith`: satu repo kusut → modular di tempat
- **`coupling-report.sh`** membaca riwayat git, untuk bahasa apa pun dan tanpa build. Hasilnya:
  - file dengan perubahan terbanyak beserta jumlah barisnya;
  - churn per area;
  - pasangan area yang sering berubah bersama, yaitu kopling tersembunyi yang tidak terlihat di graf import.
- **`scan-monolith.sh`**: laporan kopling ditambah scan arsitektur oleh opencode read-only. Hasilnya: peta area,
  graf dependensi dan siklus, matriks tabel × area (siapa menulis dan membaca), file panas yang dipakai bersama,
  kandidat modul, dan urutan ekstraksi.
- **Daftar tool analisis per stack:**
  - TypeScript: dependency-cruiser, madge;
  - Python: import-linter;
  - Java/Kotlin: ArchUnit, Spring Modulith;
  - Go, .NET, PHP (deptrac), Rails (packwerk).
  Daftar ini disertai **tabel keputusan batas modul**.
- **`ratchet.sh`** bekerja dengan checker apa pun. Pelanggaran batas yang ada sekarang menjadi baseline,
  pelanggaran baru membuat CI gagal, dan pelanggaran yang sudah diperbaiki harus dihapus dari baseline. Hasilnya,
  jumlah pelanggaran hanya bisa berkurang.
- **Playbook strangler** dalam tiga fase:
  - A, jaring pengaman: CI hijau, characterization test, kerangka modul, dan ratchet;
  - B, ekstraksi per modul: kontrak → facade → arahkan ulang pemanggil → pindahkan isi → putus akses DB → putus
    siklus → buktikan → kecilkan baseline;
  - C, perkuat batas modul.
- **Pemisahan database tanpa downtime:** kepemilikan tabel, schema per modul, read model, foreign key lintas modul
  diganti ID plus job rekonsiliasi, outbox, dan pola expand → migrate → contract.
- **Aturan paralel khusus satu repo:** file pemanggil juga punya pemilik, file panas bersama hanya punya satu
  pemilik per wave, task dibuat lebih kecil, dan worktree di-rebase sebelum review.
- **Template:** `MODULARIZATION-PLAN.md` (keputusan, peta modul, aturan batas, wave M0–M4, DoD per modul) dan
  task ekstraksi untuk agen.

### `agent-orchestrator`: Claude Code mengorkestrasi, opencode mengeksekusi
- **Perencanaan wave dan paralelisme:** graf dependensi dipecah menjadi lapisan, kepemilikan file harus terpisah,
  dan rumus `MAX_PARALLEL = min(task siap, RAM, CPU, anggaran API)`, dengan angka acuan dari server nyata.
- **Isolasi per agen:** satu git worktree dan satu branch, plus `XDG_DATA_HOME` sendiri. Tanpa itu, opencode
  paralel gagal dengan `Failed to execute statement` karena berbagi SQLite.
- **Script:**
  - `new-worktree.sh`: membuat worktree, menginstal dependensi, dan mencatat commit dasar;
  - `launch.sh`: menjalankan agen dengan header prompt yang placeholder-nya terisi dan marker selesai yang unik;
  - `watch.sh`: mencetak event untuk setiap commit, kondisi macet (`STALL`), dan `FINISHED`;
  - `resume.sh`: melanjutkan sesi agen yang berhenti di tengah;
  - `scope-check.sh`: menolak file di luar kepemilikan agen;
  - `ci-watch.sh`: mencetak hasil tiap job CI sampai run selesai.
- **Template prompt:** header agen (aturan worktree, kepemilikan, verifikasi, format laporan) dan task (temuan
  sampai file:baris, perilaku yang diminta, tes, dokumen, out-of-scope).
- **Review sebelum merge:** laporan → cek scope → baca diff berisiko → jalankan gate sendiri di hasil merge →
  push → pantau CI sampai hijau → bersih-bersih, termasuk menghapus salinan `auth.json`.
- **Penanganan masalah:** agen macet, berhenti di tengah, minta mengubah file di luar kepemilikannya, menabrak
  keputusan terkunci, dan konflik merge (dilarang `--theirs` buta).

### `hardening-review-loop`: sampai production ready, bukan sampai agen bilang selesai
- **Checklist produksi** berisi bug nyata yang lolos dari agen:
  - RLS dan role runtime database, timezone tenant;
  - `uuidv7` di PostgreSQL 16, signature webhook, self-approval;
  - TTL dan secret JWT, route publik;
  - error 400 vs 500, drift dokumen hasil generate, tes flaky, tarball berisi tes.
- **Prompt agen reviewer read-only:** temuan diberi severity, file:baris, skenario gagal yang konkret, dan tes
  pembuktiannya.
- **Siklus:** temuan dikelompokkan per kepemilikan → task perbaikan → agen → verifikasi setiap klaim → merge → CI.
  Kalau ada trade-off, Claude bertanya ke owner dan mencatatnya sebagai K-xx atau RFC.

### `monorepo-release`: rilis dan konsumsi package
- **Gate tarball:** tidak ada tes, tidak ada `node_modules`, dan setiap package yang dipublish dicek, termasuk
  package bersarang.
- **Publish ke GitHub Packages dengan alias scope.** Nama sumber tetap, misalnya `@acme/*`, karena
  `publish-github.mjs` menulis ulang tarball menjadi `@<owner>/acme-*` dengan alias npm. Dependensi internal
  tetap ter-resolve, dan script aman dijalankan ulang (versi yang sudah ada dilewati).
- **Workflow `release.yml`** memakai `GITHUB_TOKEN` (`packages: write`), jadi tidak perlu token pribadi.
- **Tag dan uji instal bersih** dari sudut pandang konsumen: tidak ada `workspace:` di lockfile, dan import nama
  asli berjalan.
- **Akses konsumen:**
  - laptop: device code untuk `read:packages`;
  - CI repo lain: `packages: read` plus *Manage Actions access*;
  - server: PAT read-only;
  - catatan untuk package yang berisi source TypeScript.

## Use case

1. **Menggabungkan beberapa produk lama menjadi satu platform modular.** Contoh: POS, HR, dan CRM dari tiga
   repo berbeda dijadikan satu "AI Business OS" yang modulnya bisa diaktifkan per tenant.
   *Skill:* `multi-repo-prd` → `agent-orchestrator` → `hardening-review-loop` → `monorepo-release`.
   *Hasil:* PRD dan kontrak terkunci, prompt pack untuk puluhan modul, modul dibangun agen secara paralel,
   lalu rilis package.
2. **Memodularkan monolith legacy tanpa menghentikan rilis.** Contoh: backend NestJS, Django, Spring, atau Rails
   dengan `order.service` 2.500 baris dan tabel `orders` yang ditulis lima fitur.
   *Skill:* `modularize-monolith` → `agent-orchestrator`.
   *Hasil:* peta modul berbasis bukti, ratchet di CI, ekstraksi bertahap tiap modul, dan database dipisah tanpa
   downtime.
3. **Menyiapkan pemecahan ke microservice nanti.** Batas modul, kontrak, dan event dibuat dulu di dalam monolith,
   sehingga memisahkan satu modul menjadi service hanya perubahan deployment.
   *Skill:* `modularize-monolith` (atau `multi-repo-prd` untuk produk baru).
4. **Mendelegasikan pekerjaan besar ke opencode di server kecil.** Agen berjalan satu per satu, terisolasi, dan
   dipantau, sementara Claude Code me-review dan merge.
   *Skill:* `agent-orchestrator`.
5. **Mengaudit hasil kerja agen AI atau tim lain sebelum produksi.**
   *Skill:* `hardening-review-loop`.
   *Hasil:* daftar temuan dengan bukti, task perbaikan, dan CI hijau.
6. **Menambah fitur lintas modul dengan keputusan sensitif**, misalnya route publik tanpa login atau batas
   umur token. Claude bertanya ke owner, mencatat keputusan (K-xx atau RFC), lalu mendelegasikan implementasinya.
   *Skill:* `hardening-review-loop` + `agent-orchestrator`.
7. **Merilis monorepo internal ke GitHub Packages** dan memberi akses ke tim platform.
   *Skill:* `monorepo-release`.
8. **Mencari kopling tersembunyi** sebelum refactor atau estimasi. Satu perintah `coupling-report.sh` menunjukkan
   file paling berisiko dan area yang selalu berubah bersama.
   *Skill:* `modularize-monolith` (script-nya bisa dipakai sendiri).

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

## Contoh prompt

Ucapkan dalam bahasa apa pun. Skill aktif otomatis dari konteks, atau sebut namanya agar pasti.

### Perencanaan dari beberapa repo (`multi-repo-prd`)
```
Pelajari repo ~/Github/pos-app, ~/Github/hr-app, dan ~/Github/crm-app. Aku mau semuanya jadi satu produk
modular di repo github.com/acme/acme-modular. Pakai multi-repo-prd: scan tiap repo pakai opencode, ajak aku
brainstorming keputusan penting, lalu buat PRD, kontrak, design, catalog, dan oneshot prompt per modul.
```
```
Kunci arsitektur dan tampilannya mengikuti dashboard di repo pos-app. Tambahkan modul projects dan timesheet.
Catat sebagai keputusan owner.
```

### Memodularkan satu repo besar (`modularize-monolith`)
```
Repo ~/Github/legacy-api ini terlalu kompleks. Pakai modularize-monolith: ukur kopling (import, tabel,
co-change), usulkan peta modul, lalu tanya aku keputusan yang perlu. Jangan ubah kode dulu.
```
```
Jalankan coupling-report untuk apps/backend/src/modules di depth 5, enam bulan terakhir. Jelaskan area mana
yang sebaiknya jadi satu modul dan mana yang butuh kontrak.
```
```
Siapkan wave M0: characterization test untuk 10 hotspot teratas, kerangka modules/, dependency-cruiser,
dan ratchet di CI. Setelah itu ekstraksi modul billing dulu, dalam task kecil.
```

### Orkestrasi agen (`agent-orchestrator`)
```
Jalankan wave W1 batch pertama pakai opencode. Server ini 4 CPU / 8 GB, jadi hitung dulu berapa agen yang
aman paralel. Satu worktree per agen, review setiap hasil sebelum merge, dan pantau CI sampai hijau.
```
```
Server kehabisan resource. Jalankan agen satu per satu saja dan kabari aku setiap milestone.
```
```
Agen p3-billing berhenti di tengah. Lanjutkan sesinya, lalu review scope dan diff-nya.
```

### Review dan pengerasan (`hardening-review-loop`)
```
Cek pekerjaan opencode di repo ini. Apakah arahnya sudah benar? Buat daftar temuan dengan file:baris dan
tingkat keparahan.
```
```
Perbaiki semua yang masih kurang sampai production ready. Orkestrasi beberapa opencode untuk fix-nya,
commit, push, dan pastikan CI hijau.
```
```
Fitur booking tanpa login boleh asal ada email atau nomor WhatsApp untuk verifikasi. Umur token JWT maksimal
48 jam. Catat keputusan ini lalu implementasikan.
```

### Rilis (`monorepo-release`)
```
Publish semua package ke GitHub Packages organisasi kita. Kode tetap pakai scope @acme. Jalankan lewat
GitHub Actions, buat tag, lalu uji instal bersih di proyek kosong.
```
```
Bagaimana tim platform menginstal package-nya? Tulis cara akses read:packages untuk laptop, CI, dan server.
```

### End-to-end dalam satu sesi
```
Mulai dari scan 3 repo ini sampai rilis: rencana → bangun modul pakai opencode (satu per satu) → review
dan perbaiki sampai production ready → publish. Laporkan progres dalam Bahasa Indonesia.
```

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
