# apptricks — AI EXECUTION GUIDE

> Repo: `apptricks` (terinspirasi winetricks). Install via `./setup.sh`.
> Pola wajib: **1 app exe = 1 Wine prefix** di `<BASE>/.[NamaApp]`
> Resolusi BASE: `$APPTRICKS_BASE` > `~/.config/apptricks/config` >
> default `~/.local/share/apptricks/prefixes`.

## 1. Aturan Keras (jangan dilanggar)

1. **JANGAN** pakai `~/.wine` untuk app baru. Biarkan tidak tersentuh.
2. **JANGAN** `export WINEPREFIX` / `APPTRICKS_BASE` global di `.bashrc`.
   Selalu eksplisit per perintah:
   `WINEPREFIX="<BASE>/.NamaApp" wine ...`
3. **JANGAN** ubah mapping `C:` di `winecfg`. Biarkan default.
4. Selalu quote path: `"<BASE>/.AppKu"`, `"$HOME/Downloads/setup.exe"`.
5. Gunakan binary `wine` (bukan `wine64`).
6. Prefix hanya di filesystem POSIX (`ext4` dsb). Jangan di NTFS/FAT.
7. **JANGAN** pakai `sudo` untuk wine/prefix. Owner harus user biasa.
8. **JANGAN** hardcode nama app apa pun di `bin/`. Mapping khusus hanya via
   data user di `~/.config/apptricks/aliases` (format `pola=nama`).

## 2. Helper Kanonis: `apptricks` (`~/.local/bin/apptricks`, di `$PATH`)

```
apptricks list
apptricks init <Name>                        # .AppKu atau AppKu (otomatis dinormalisasi ke .Nama)
apptricks install <Name> <setup.exe> [args]  # validasi file + prefix ada, lalu wine setup.exe
apptricks run <Name> <exe> [args]            # jalankan exe di dalam prefix
apptricks cfg <Name>                         # winecfg
apptricks explorer <Name>                    # wine explorer
apptricks uninstaller <Name>                 # daftar program terinstall
apptricks kill <Name>                        # wineserver -k
apptricks path <Name>                        # cetak path prefix
```

Dilarang membuat helper tandingan. Kalau kurang, edit `bin/` di repo,
lalu install ulang via `./setup.sh` — jangan edit hasil install langsung.

## 3. SOP AI: Install App Baru

```bash
# 1. Init (sekali saja per app)
apptricks init .AppKu
# Hasil: <BASE>/.AppKu/drive_c/, system.reg, user.reg

# 2. Install — biarkan folder installer default C:\Program Files\...
apptricks install .AppKu "$HOME/Downloads/setup-appku.exe"

# 3. Verifikasi
ls "<BASE>/.AppKu/drive_c/Program Files/"
apptricks uninstaller .AppKu
```

Jalankan: `apptricks run .AppKu "<BASE>/.AppKu/drive_c/Program Files/AppKu/app.exe"`

## 4. SOP AI: Menjalankan / Debug

```bash
apptricks list
WINEPREFIX="<BASE>/.AppKu" winecfg
WINEPREFIX="<BASE>/.AppKu" wine explorer
WINEPREFIX="<BASE>/.AppKu" wineserver -k
```

Prefix corrupt → hapus isi prefix lalu `apptricks init` ulang.
Jangan coba repair registry manual.

Installer keluar non-nol (mis. kode 1) padahal app terinstall & jalan =
NORMAL (installer NSIS/dkk rutin begitu di Wine). GUI menanganinya via
`handle_install_rc()`: info + tetap tawarkan launcher; hanya batal bila
prefix hilang. Bukti/lacak: `<prefix>/apptricks-install.log` (ditulis via
`tee`, exit code asli wine tetap diteruskan berkat `pipefail`).

## 5. Struktur

```
<BASE>/
  .AppKu/              # WINEPREFIX: drive_c/, system.reg, user.reg, dosdevices/
    drive_c/Program Files/...   # hasil installer
    drive_c/Portable/...        # hasil impor portable (import_portable)
  .NamaAppLain/        # app berikutnya, pola sama
~/.local/bin/apptricks{,-gui}   # hasil install setup.sh (jangan edit langsung)
~/.config/apptricks/config      # APPTRICKS_BASE="..."
~/.config/apptricks/aliases     # mapping saran nama (data user, tidak di repo)
```

## 6. GUI + Klik-kanan Dolphin

GUI: `apptricks-gui` (Zenity, tanpa dep baru). Menu: Install exe / Jalankan
app / List / Init / Winecfg / Uninstaller. Argumen headless untuk service menu:
`apptricks-gui --install <file>`, `--run-one <file>`, `--suggest <file>`.

Klik-kanan Dolphin: `share/kio/servicemenus/apptricks.desktop`
(`KonqPopupMenu/Plugin`, Mime exe+msi, label Inggris): Install to Prefix... /
Run with Prefix... Setelah install/ubah, `setup.sh` me-refresh
`kbuildsycoca6/5` otomatis. `Run with` = jalankan exe dengan konteks prefix
(tanpa install); bila exe di luar prefix, tawarkan impor portable
(`import_portable()` → salin folder ke `drive_c/Portable/<App>/`).
WAJIB `chmod +x` semua .desktop user-local (service-menu, launcher manager,
launcher per-app) — KDE/KIO menolak eksekusi tanpanya ("not owned by root and
executable flag not set"). `setup.sh` dan `make_launcher()` sudah otomatis.

`bin/apptricks` menonaktifkan `winemenubuilder.exe` via `WINEDLLOVERRIDES`
agar Wine tidak membuat entri menu/Desktop otomatis yang menduplikasi
launcher apptricks. Override per-perintah: `WINEMENUBUILDER=1 apptricks ...`.

Launcher per-app (`apptricks-<Nama>.desktop`) DITAWARKAN OTOMATIS dengan
pilihan lokasi (`offer_launcher()`): menu / Desktop / keduanya. Desktop =
`~/Desktop/<Nama>.desktop` + `chmod +x` (Plasma: double-click pertama pilih
Trust and Launch). Ditawarkan setelah install sukses (user menunjuk exe utama
via file-selection) dan setelah impor portable sukses (exe sudah diketahui).
JANGAN pernah membuat .desktop per-app dengan menebak path exe sebelum
install/impor terbukti berhasil.

Aturan saran nama (`suggest_name()`, generik): buang ekstensi + kata
setup/installer + arsitektur, gabung alnum, kapitalisasi tiap kata
(`setup_contoh2024.exe` -> `.Contoh2024`); selalu dot-prefix; user bisa edit
sebelum OK. Flow: pilih prefix ada -> langsung install; pilih Baru -> entry
saran -> auto `apptricks init` bila belum ada -> `apptricks install`.

## 7. Setup & Verifikasi di Mesin Baru

```bash
./setup.sh                 # interaktif, 8 langkah ber-progress
./setup.sh --yes           # non-interaktif (pakai semua default)
./setup.sh --base DIR      # paksa lokasi prefix
./setup.sh --no-desktop    # lewati integrasi Dolphin/menu (server/TTY)
./setup.sh --skip-deps     # lewati cek/install wine+zenity
./uninstall.sh [--purge]   # hapus hasil install (purge = +config & prefix)
```

Test aman tanpa menyentuh sistem: `HOME=/tmp/at-test ./setup.sh --yes --skip-deps`
