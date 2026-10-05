# agent-build-playbook

[English](README.md) · **Bahasa Indonesia**

Kumpulan skill dan script yang membuat satu **AI utama dengan reasoning tinggi** (koordinator) bisa merencanakan
pekerjaan lalu mendispatch-nya ke **agen coding berbasis CLI** (worker: opencode, pi, Antigravity, atau CLI apa
pun). Setiap worker bekerja di git worktree sendiri, lalu koordinator me-review dan merge semuanya sampai CI
hijau.

Kebanyakan orang hanya butuh bagian **orkestrasi agen**. Bagian ini bisa dipakai di repo apa pun dan bahasa
pemrograman apa pun, tanpa dokumen perencanaan. Skill lainnya menambahkan perencanaan untuk pekerjaan yang lebih
besar:
- **Beberapa repo → satu produk modular baru** (`multi-repo-prd`).
- **Satu repo yang terlalu kompleks → modular di tempat** (`modularize-monolith`). Aplikasi tetap bisa dirilis di
  setiap langkah.
- **Review dan perbaikan sampai production ready** (`hardening-review-loop`), serta **rilis package**
  (`monorepo-release`).

**Isi:** [Mulai cepat: orkestrasi saja](#mulai-cepat-orkestrasi-agen-saja) · [Model](#model-koordinator-kuat-worker-ringan) ·
[Skill](#skill) · [Pilih skill](#pilih-skill-yang-mana) · [Fitur](#fitur) · [Use case](#use-case) ·
[Instalasi](#instalasi) · [Contoh prompt](#contoh-prompt) · [Prinsip](#prinsip)

```
                        ┌────────────────────────────────────────────┐
 Anda ── tujuan ───────▶│  KOORDINATOR (AI utama, reasoning tinggi)  │
                        │  Claude Opus 5.5 / GPT 6 Astra, effort high │
                        │  baca kode · pecah kerja · tulis prompt     │
                        │  review diff · merge · pantau CI            │
                        └──────┬───────────────┬───────────────┬─────┘
            tujuan jelas + kepemilikan file + tes + out-of-scope
                               ▼               ▼               ▼
                        ┌──────────┐    ┌──────────┐    ┌──────────┐
                        │ opencode │    │    pi    │    │   agy    │   WORKER
                        │ worktree │    │ worktree │    │ worktree │   (reasoning rendah–sedang)
                        │ branch A │    │ branch B │    │ branch C │
                        └──────────┘    └──────────┘    └──────────┘
```

## Mulai cepat: orkestrasi agen saja

Prasyarat: `git`, `jq`, `gh` (sudah login, untuk memantau CI), dan minimal satu CLI worker (opencode, pi, atau
Antigravity `agy`) yang sudah login.

```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/agent-build-playbook
~/agent-build-playbook/install.sh claude        # atau: all | opencode | hermes | antigravity | antigravity-cli
```

Lalu, di proyek Anda, katakan ke AI utama:

```
Pakai agent-orchestrator. Tujuan: <yang Anda mau>. Pecah jadi task dengan kepemilikan file yang jelas,
dispatch ke opencode (effort low) satu per satu, review setiap diff sebelum merge, dan jaga CI tetap hijau.
```

Ini yang dilakukan koordinator dengan script dari skill tersebut:

```sh
export ORCH_ROOT=~/code/myrepo-wt/_orchestration                         # jangan di /tmp
cp ~/agent-build-playbook/skills/agent-orchestrator/scripts/orch.env.example $ORCH_ROOT/orch.env  # REPO, EXECUTOR…
S=~/agent-build-playbook/skills/agent-orchestrator/scripts
$S/new-worktree.sh fix-login-timeout                                      # worktree + branch
#   … menulis $ORCH_ROOT/prompts/fix-login-timeout.md (tujuan, kepemilikan, tes, out-of-scope)
$S/launch.sh fix-login-timeout '`src/auth/**`, `tests/auth/**`' opencode   # worker berjalan (background)
$S/watch.sh fix-login-timeout                                             # commit / STALL / FINISHED
$S/scope-check.sh fix-login-timeout '^(src/auth/|tests/auth/)'            # tidak ada file di luar kepemilikan
#   … review diff, menjalankan tes sendiri, merge, lalu:
$S/ci-watch.sh --latest main                                              # sampai CI hijau
```

Anda tidak perlu menjalankan script ini secara manual, kecuali memang ingin. Koordinator mengikuti prosedur di
[`skills/agent-orchestrator/SKILL.md`](skills/agent-orchestrator/SKILL.md).

## Model: koordinator kuat, worker ringan

| Peran | Rekomendasi | Reasoning | Alasan |
|---|---|---|---|
| **Koordinator** (AI yang Anda ajak bicara) | **Claude Opus 5.5** atau **GPT 6 Astra**, atau model paling cerdas yang Anda punya | **High** | Koordinator membaca kode, memutuskan batas modul dan trade-off, menulis prompt, dan menilai diff. Kualitas hasil ditentukan di sini. |
| **Worker** (agen CLI yang di-dispatch) | Model coding yang cukup mumpuni lewat **opencode**, **pi**, atau **Antigravity `agy`** (atau CLI custom) | **Rendah–sedang** | Setiap prompt datang dengan tujuan, kepemilikan file, perilaku yang diminta, tes, dan out-of-scope yang jelas, jadi eksekusinya tidak butuh banyak berpikir. Naikkan hanya untuk task algoritmik atau setelah percobaan gagal. |

Cara mengaturnya:
- **Koordinator di Claude Code:** buka `/model`, pilih Opus 5.5, dan set effort ke **high**. Di tool lain, pilih
  model terkuat dan setelan thinking atau effort tertinggi.
- **Worker:** atur di `orch.env`:
  ```sh
  EXECUTOR=opencode      # opencode | pi | agy | custom
  EXEC_MODEL=""          # kosong = default tool; opencode memakai provider/model
  EXEC_EFFORT=low        # opencode --variant · pi --thinking · agy --effort
  ```
  Executor bisa diganti per task dengan `launch.sh <task> '<kepemilikan>' pi`. Detailnya ada di
  [`executors.md`](skills/agent-orchestrator/references/executors.md).

## Skill

| Skill | Pakai saat | Isi |
|---|---|---|
| [`agent-orchestrator`](skills/agent-orchestrator/SKILL.md) ⭐ | Anda ingin mendelegasikan kerja ke agen lain: "orkestrasi", "dispatch", "jalankan agen paralel / satu per satu" | Script worktree, launch (opencode / pi / agy / custom), watch, resume, scope-check, dan ci-watch; template prompt worker; hitungan paralelisme; panduan review dan merge |
| [`modularize-monolith`](skills/modularize-monolith/SKILL.md) | Satu repo terlalu kompleks dan Anda ingin dipecah menjadi modul, atau disiapkan untuk menjadi service nanti | Laporan kopling dari git, scan arsitektur, ratchet pelanggaran batas, playbook strangler, pemisahan DB tanpa downtime, template rencana dan task |
| [`multi-repo-prd`](skills/multi-repo-prd/SKILL.md) | Anda ingin menggabungkan beberapa repo menjadi satu produk modular | Scan per repo, log keputusan owner, template PRD / arsitektur / design / catalog, prompt pack one-shot per modul |
| [`hardening-review-loop`](skills/hardening-review-loop/SKILL.md) | Anda ingin hasil kerja agen dicek dan diperbaiki sampai production ready | Checklist produksi, prompt reviewer read-only, siklus temuan → fix → verifikasi |
| [`monorepo-release`](skills/monorepo-release/SKILL.md) | Anda perlu mem-publish package dari monorepo supaya bisa dipasang tim lain | Gate isi package, publish ke GitHub Packages dengan alias scope, workflow rilis, uji instal bersih |

### Pilih skill yang mana?

| Kondisi Anda | Mulai dari | Lalu |
|---|---|---|
| Sudah punya task atau rencana, ingin dikerjakan agen | `agent-orchestrator` | `hardening-review-loop` |
| Satu codebase besar yang kusut | `modularize-monolith` | `agent-orchestrator` → `hardening-review-loop` |
| Beberapa repo yang ingin digabung menjadi satu produk | `multi-repo-prd` | `agent-orchestrator` → `hardening-review-loop` → `monorepo-release` |
| Agen sudah mengerjakan, tapi Anda ragu kualitasnya | `hardening-review-loop` | `agent-orchestrator` untuk fix-nya |
| Monorepo yang perlu dipakai tim lain | `monorepo-release` | — |

## Fitur

### `agent-orchestrator`: koordinator merencanakan, worker mengeksekusi
- **Mandiri, untuk repo dan stack apa pun.** Tidak perlu PRD atau struktur khusus. `INSTALL_CMD` bebas
  (`npm ci`, `pip install …`, `go mod download`, …).
- **Banyak executor:** opencode, pi, Antigravity `agy`, atau CLI custom. Model dan effort bisa diatur global
  maupun per task.
- **Isolasi:** satu git worktree dan branch per worker, plus folder data atau sesi sendiri. Tanpa itu, opencode
  yang jalan paralel bentrok di database yang sama.
- **Perencanaan paralel:**
  - kerja dipecah menjadi irisan kepemilikan yang tidak tumpang-tindih;
  - task disusun berlapis menurut dependensi;
  - `MAX_PARALLEL = min(task siap, RAM, CPU, anggaran API)`;
  - di mesin kecil atau yang dipakai bersama, worker dijalankan satu per satu.
- **Script:**
  - `new-worktree.sh`: membuat worktree dan branch, menginstal dependensi, dan mencatat commit dasar;
  - `launch.sh`: menjalankan worker dengan marker selesai yang unik;
  - `watch.sh`: mencetak event commit, `STALL`, dan `FINISHED`;
  - `resume.sh`: melanjutkan sesi yang sama;
  - `scope-check.sh`: menolak file di luar kepemilikan worker;
  - `ci-watch.sh`: mencetak hasil tiap job CI sampai run selesai.
- **Template prompt** yang bisa dieksekusi worker dengan effort rendah: header umum (aturan worktree,
  kepemilikan, verifikasi, format laporan) dan prompt task (tujuan, kebutuhan sampai file:baris, tes,
  out-of-scope).
- **Review sebelum merge:** laporan → scope → diff berisiko → gate dijalankan ulang oleh koordinator → merge →
  CI hijau → bersih-bersih.
- **Playbook masalah:** worker macet, berhenti di tengah, meminta mengubah file di luar kepemilikannya, butuh
  keputusan owner, dan konflik merge.

### `modularize-monolith`: modular di tempat, selalu bisa rilis
- **`coupling-report.sh`** membaca riwayat git, untuk bahasa apa pun dan tanpa build. Isinya: hotspot (churn ×
  ukuran), churn per area, dan area yang sering berubah bersama (kopling tersembunyi).
- **`scan-monolith.sh`** menjalankan worker read-only yang memetakan area, graf dependensi dan siklus, kode mana
  menyentuh tabel mana, file panas bersama, kandidat modul, dan urutan ekstraksi.
- **Tool analisis per stack:** dependency-cruiser/madge, import-linter, ArchUnit/Spring Modulith, Go, .NET,
  deptrac, packwerk. Hasilnya menjadi **tabel keputusan batas modul**.
- **`ratchet.sh`** bisa dipakai dengan checker apa pun. Pelanggaran yang ada sekarang menjadi baseline,
  pelanggaran baru membuat CI gagal, dan baseline hanya bisa mengecil.
- **Playbook strangler:**
  - jaring pengaman: characterization test, kerangka modul, ratchet;
  - ekstraksi per modul, mulai dari modul pinggiran: kontrak → facade → arahkan ulang pemanggil → pindahkan isi
    → putus akses DB → putus siklus;
  - perkuat batas modul.
- **Pemisahan DB tanpa downtime:** kepemilikan tabel, schema per modul, read model, foreign key lintas modul
  diganti ID plus rekonsiliasi, outbox, dan pola expand → migrate → contract.

### `multi-repo-prd`: beberapa repo → rencana satu produk modular
- Scan read-only per repo sumber, di-pin ke satu commit. Setiap klaim menyebut path.
- Keputusan owner ditanyakan paling banyak empat sekaligus, masing-masing dengan rekomendasi, lalu dicatat
  sebagai `K-xx` supaya tidak ditanyakan ulang.
- Template: PRD, kontrak arsitektur yang dikunci, design system yang dikunci, catalog dengan coverage map (setiap
  fitur sumber punya rumah atau alasan dibuang), rencana orkestrasi, dan proses RFC.
- Prompt pack one-shot: common brief, brief per wave, dan spec per modul dengan acceptance yang bisa dites,
  sehingga banyak agen bisa membangun paralel tanpa mengarang keputusan.

### `hardening-review-loop`: selesai berarti terverifikasi, bukan "kata agennya"
- Checklist produksi: akses data dan tenancy, auth dan approval, integrasi dan webhook, waktu / uang /
  identifier, konkurensi, penanganan error, kebersihan CI dan rilis, serta dokumentasi.
- Prompt reviewer read-only. Setiap temuan punya severity, file:baris, skenario gagal yang konkret, dan tes yang
  akan membuktikan perbaikannya.
- Siklus: temuan → task perbaikan per kepemilikan → worker → setiap klaim diverifikasi → merge → CI. Trade-off
  diputuskan owner dan dicatat.

### `monorepo-release`: rilis package yang bisa dipasang tim lain
- Gate isi package: hanya yang dibutuhkan konsumen, dan dicek untuk setiap package yang dipublish.
- Publish ke GitHub Packages dengan scope sumber tetap utuh lewat alias npm. Publish berjalan dari workflow GitHub
  Actions dengan `GITHUB_TOKEN`, lalu diberi tag dan diuji instal bersih.
- Panduan akses untuk laptop, CI repo lain, dan server.

## Use case

1. **Mendelegasikan fitur atau refactor ke agen murah dengan aman.** Model kuat merencanakan, worker yang lebih
   murah mengeksekusi di worktree terisolasi, dan tidak ada yang di-merge tanpa review dan CI hijau.
   *(agent-orchestrator)*
2. **Memaksimalkan server kecil atau server bersama.** Worker dijalankan satu per satu dengan pemantau dan resume,
   jadi satu sesi yang macet tidak ikut menjatuhkan mesin. *(agent-orchestrator)*
3. **Mencampur tool sesuai kekuatannya.** Misalnya pi untuk fix cepat, opencode untuk task panjang, dan
   Antigravity bila tool bawaannya membantu, semua di bawah satu koordinator. *(agent-orchestrator)*
4. **Merapikan monolith legacy tanpa rewrite.** Batas modul berbasis bukti, ratchet di CI, ekstraksi dari modul
   pinggiran, dan pemisahan database tanpa downtime. *(modularize-monolith → agent-orchestrator)*
5. **Menyiapkan microservice nanti.** Kontrak dan event dibuat dulu di dalam monolith, sehingga memisahkan modul
   cukup dengan perubahan deployment. *(modularize-monolith)*
6. **Menggabungkan beberapa produk menjadi satu platform.** Satu PRD, arsitektur dan design yang dikunci, prompt
   pack, dan modul dibangun paralel. *(multi-repo-prd → agent-orchestrator)*
7. **Mengaudit kode buatan AI sebelum produksi.** Temuan konkret, task perbaikan, dan klaim yang terverifikasi.
   *(hardening-review-loop)*
8. **Menemukan kopling tersembunyi sebelum estimasi.** Satu perintah menunjukkan file paling berisiko dan area
   yang selalu berubah bersama. *(coupling-report.sh)*
9. **Mem-publish package internal untuk tim lain.** *(monorepo-release)*

## Instalasi

Semua skill memakai format standar **Agent Skills**: satu folder berisi `SKILL.md` (frontmatter `name` dan
`description`) plus `scripts/`, `templates/`, dan `references/`. Claude Code, opencode, Hermes, dan Antigravity
membaca format ini; bedanya hanya di folder yang mereka baca. Script memakai bash, jadi di Windows gunakan WSL.

### Semua sekaligus

```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/agent-build-playbook
cd ~/agent-build-playbook && ./install.sh all    # atau pilih: claude opencode agents hermes antigravity antigravity-cli
```

`install.sh` membuat **symlink**, jadi cukup `git pull` untuk memperbarui semua tool. Script ini tidak pernah
menimpa folder asli yang namanya sama. Pakai `SKILLS_COPY=1` untuk menyalin file, bila tool atau sandbox tidak
mengikuti symlink.

| Target | Lokasi global | Dipakai oleh |
|---|---|---|
| `claude` | `~/.claude/skills/<skill>` | Claude Code (opencode juga membacanya) |
| `opencode` | `~/.config/opencode/skills/<skill>` | opencode |
| `agents` | `~/.agents/skills/<skill>` | opencode dan tool lain yang membaca `.agents/skills` |
| `antigravity` | `~/.gemini/config/skills/<skill>` | Antigravity IDE |
| `antigravity-cli` | `~/.gemini/antigravity-cli/skills/<skill>` | Antigravity CLI (`agy`) |
| `hermes` | `~/.hermes/skills/agent-build-playbook/` | Hermes Agent (satu kategori berisi semua skill) |

### Claude Code
- **Sebagai plugin, tanpa clone:**
  ```
  /plugin marketplace add sammyjason39/agent-build-playbook
  /plugin install agent-build-playbook@agent-build-playbook
  ```
  Untuk update: `/plugin marketplace update agent-build-playbook`.
- **Sebagai skill personal:** `./install.sh claude`.
- **Per proyek:** salin atau symlink `skills/*` ke `<repo>/.claude/skills/` lalu commit, supaya satu tim ikut
  mendapatkannya.

### opencode
opencode membaca `~/.config/opencode/skills/`, `~/.claude/skills/`, dan `~/.agents/skills/` (global), serta
`.opencode/skills/`, `.claude/skills/`, dan `.agents/skills/` (per proyek).
```sh
./install.sh opencode
opencode debug skill | grep -E '"name": "(agent-orchestrator|modularize-monolith|multi-repo-prd|hardening-review-loop|monorepo-release)"'
```

### Hermes Agent
- **Dari GitHub sebagai tap:**
  ```sh
  hermes skills tap add sammyjason39/agent-build-playbook
  hermes skills install sammyjason39/agent-build-playbook/agent-orchestrator
  hermes skills install sammyjason39/agent-build-playbook/modularize-monolith
  hermes skills install sammyjason39/agent-build-playbook/multi-repo-prd
  hermes skills install sammyjason39/agent-build-playbook/hardening-review-loop
  hermes skills install sammyjason39/agent-build-playbook/monorepo-release
  ```
  Untuk melihat isi skill sebelum memasang: `hermes skills inspect sammyjason39/agent-build-playbook/<skill>`.
  Untuk update: `hermes skills check` lalu `hermes skills update`.
- **Dari clone (paling cocok kalau Anda juga mengedit skill):** tambahkan ke `~/.hermes/config.yaml`:
  ```yaml
  skills:
    external_dirs:
      - ~/agent-build-playbook/skills
  ```
  Bisa juga dengan `./install.sh hermes`.
- **Per proyek:** taruh skill di `<repo>/.agents/skills/` atau `<repo>/.hermes/skills/`, lalu jalankan
  `hermes skills trust` di repo itu.

### Antigravity (IDE dan CLI `agy`)
IDE dan CLI memakai folder global yang **berbeda**:
```sh
./install.sh antigravity        # IDE: ~/.gemini/config/skills/  (lokasi lama ~/.gemini/antigravity/skills/ juga dibaca)
./install.sh antigravity-cli    # CLI: ~/.gemini/antigravity-cli/skills/
```
Per proyek, keduanya membaca `<workspace>/.agents/skills/<skill>/`. Setelah memasang, muat ulang workspace atau
mulai sesi `agy` baru.

### Catatan kompatibilitas
- Skill ini lahir dari pengerjaan dengan **Claude Code sebagai koordinator**. Di Hermes atau Antigravity, agen
  yang Anda ajak bicara mengambil peran itu, dan script tetap mendispatch worker lewat `launch.sh`.
- Fitur khusus Claude Code seperti Monitor dan shell background punya padanannya di tool lain:
  - jalankan `launch.sh` di background (`nohup … &`);
  - pantau dengan `watch.sh`;
  - pantau CI dengan `ci-watch.sh`.
- Script menemukan konfigurasi lewat `ORCH_ROOT` (`export ORCH_ROOT=…`, lihat
  [`opencode.md`](skills/agent-orchestrator/references/opencode.md)).

## Contoh prompt

Boleh dalam bahasa apa pun. Skill aktif otomatis dari konteks, atau sebut namanya agar pasti.

### Orkestrasi saja (`agent-orchestrator`)
```
Pakai agent-orchestrator. Tambahkan rate limiting di API publik kita: tentukan desainnya, pecah jadi task
dengan kepemilikan file yang jelas, dispatch ke opencode effort low, review setiap diff, merge, dan jaga CI hijau.
```
```
Mesin ini 4 CPU dan 8 GB RAM. Hitung berapa worker yang aman jalan paralel, lalu kerjakan backlog di
docs/todo.md. Kabari aku setiap milestone.
```
```
Fix-fix kecil dispatch ke pi (thinking low), task migrasi ke opencode (variant medium). Satu worktree per task,
dan tidak ada yang di-merge sebelum tesnya lulus di main.
```
```
Worker untuk task fix-search-pagination berhenti di tengah. Lanjutkan sesinya, lalu cek scope dan diff-nya.
```

### Satu repo kompleks (`modularize-monolith`)
```
Repo ini terlalu kompleks. Pakai modularize-monolith: ukur kopling (import, tabel, co-change), usulkan peta
modul, dan tanyakan hanya keputusan yang penting. Jangan ubah kode dulu.
```
```
Jalankan coupling report untuk src/ di depth 3, 12 bulan terakhir. Jelaskan area mana yang sebaiknya jadi satu
modul dan mana yang butuh kontrak di antaranya.
```
```
Siapkan wave M0: characterization test untuk 10 hotspot teratas, kerangka modul, dan boundary checker dengan
ratchet di CI. Setelah itu ekstraksi modul notifications dulu, dalam task kecil.
```

### Beberapa repo (`multi-repo-prd`)
```
Pelajari ~/code/shop-app, ~/code/inventory-app, dan ~/code/crm-app. Aku mau satu produk modular di repo baru.
Pakai multi-repo-prd: scan tiap repo, ajak aku brainstorming keputusan penting, lalu tulis PRD, arsitektur,
design system, catalog, dan prompt one-shot per modul.
```

### Review dan perbaikan (`hardening-review-loop`)
```
Review hasil kerja agen di repo ini. Apakah arahnya sudah benar? Buat daftar temuan dengan file:baris dan severity.
```
```
Perbaiki semua yang masih kurang sampai production ready. Orkestrasi worker untuk fix-nya, commit, push, dan
pastikan CI hijau.
```
```
Endpoint export boleh diakses anonim asalkan request-nya ditandatangani. Catat keputusan ini lalu implementasikan.
```

### Rilis (`monorepo-release`)
```
Publish semua package ke GitHub Packages organisasi kita, dengan scope sumber tetap. Jalankan lewat GitHub
Actions, beri tag, lalu uji instal bersih di proyek kosong.
```

### End-to-end
```
Dari perencanaan sampai rilis: modularkan repo ini, kerjakan task-nya dengan worker satu per satu, review dan
perkuat sampai production ready, lalu publish. Laporkan progres dalam Bahasa Indonesia.
```

## Prinsip

- **Koordinator kuat, worker ringan.** Pemikirannya masuk ke prompt, jadi eksekusinya bisa murah.
- **Prompt ditulis setelah membaca kode.** Setiap prompt punya tujuan, file:baris, perilaku yang diminta, tes,
  dan out-of-scope.
- **Kepemilikan eksklusif per worker:** satu worktree, satu branch, satu folder data.
- **Laporan worker hanyalah klaim.** Koordinator mengecek scope, membaca diff, menjalankan gate sendiri, dan
  menunggu CI hijau sebelum menyatakan selesai.
- **Keputusan owner dicatat sekali** (tabel keputusan, ADR, atau RFC) dan tidak ditanyakan dua kali.
- **Mesin kecil → satu worker sekaligus.** Rumusnya ada di
  [`parallelism.md`](skills/agent-orchestrator/references/parallelism.md).
- **Lapor ke owner per milestone**, dalam bahasanya, dan sebut kegagalan apa adanya.

Asal-usul: skill ini disarikan dari pengerjaan nyata, saat satu koordinator mengarahkan agen CLI membangun sekitar
40 modul, menjalani beberapa siklus pengerasan, dan merilis package.
