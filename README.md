# apptricks

Kelola aplikasi Windows di Linux dengan pola **1 app = 1 Wine prefix terisolasi**.
Terinspirasi `winetricks`, tapi fokus ke isolasi prefix per aplikasi + GUI
klik-kanan ala Windows.

```text
<BASE>/.AppKu/        ← WINEPREFIX untuk AppKu
<BASE>/.AppLain/      ← WINEPREFIX untuk AppLain (tidak saling mengganggu)
```

## Fitur

- **CLI** `apptricks`: `list init install run cfg explorer uninstaller kill path`
- **GUI Zenity** `apptricks-gui`: menu lengkap + saran nama prefix otomatis
- **Klik kanan di Dolphin**: `Install ke Prefix...` / `Jalankan dengan Prefix...`
- **Launcher otomatis**: setelah install sukses, ditawari buatkan `.desktop`
- **Lokasi prefix bisa diatur** (`APPTRICKS_BASE` / file config), default XDG
- **`~/.wine` tidak pernah disentuh**

## Kebutuhan

- `bash`, `wine` (wajib untuk init/install; CLI/GUI bisa dibuka tanpanya)
- `zenity` (wajib untuk GUI; CLI tetap jalan tanpanya)
- Opsional: KDE (`kbuildsycoca6/5`) untuk refresh menu otomatis

`setup.sh` mendeteksi dan menawarkan install yang kurang
(`pacman`/`apt`/`dnf`/`zypper`).

## Install

```bash
git clone <url> apptricks && cd apptricks
./setup.sh            # interaktif, 8 langkah dengan progress
```

Opsi: `--yes` (non-interaktif) · `--base DIR` (lokasi prefix) ·
`--no-desktop` (tanpa integrasi Dolphin/menu) · `--skip-deps` ·
`--help`

Uninstall: `./uninstall.sh` (`--purge` untuk hapus config & prefix juga).

## Pakai

```bash
apptricks init .AppKu
apptricks install .AppKu ~/Downloads/setup-appku.exe
apptricks run .AppKu "<BASE>/.AppKu/drive_c/Program Files/AppKu/app.exe"
```

atau klik kanan `setup.exe` di Dolphin → **Install ke Prefix...**

## Konfigurasi (`~/.config/apptricks/`)

- `config` — satu baris: `APPTRICKS_BASE="/path/ke/prefixes"`
- `aliases` — mapping saran nama GUI, format `pola=nama` (lihat `config/aliases.example`)

## Isi repo

```text
setup.sh uninstall.sh README.md LICENSE
bin/apptricks bin/apptricks-gui
share/kio/servicemenus/apptricks.desktop
share/applications/apptricks-gui.desktop
config/aliases.example
docs/AGENTS.md        # panduan untuk AI/automation
```

Lisensi: MIT.
