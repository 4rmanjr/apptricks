# BUGS & status apptricks

Diperbarui: 2026-11-18 · diuji dengan bash 5.3, Wine 11.22 (build WoW64), zenity/wine disimulasikan.
Daftar ini sengaja jujur: yang belum diuji nyata ditulis sebagai batasan, bukan sebagai "sudah jalan".

## 1. Sudah diperbaiki

| Gejala | Penyebab | Perbaikan |
|---|---|---|
| `uninstall.sh --purge` tidak pernah menawarkan/menghapus prefix | `BASE=""` lalu source config yang mengisi `APPTRICKS_BASE`, jadi `[[ -n "$BASE" ]]` selalu salah | baca `APPTRICKS_BASE` setelah source config |
| `./setup.sh --help` hanya mencetak satu baris | `sed -n '2,/^#$/p'`: baris 2 memang `#`, rentang langsung ditutup | ambil header sampai baris `set -uo pipefail` |
| `apptricks init ../../x` membuat direktori di luar BASE | `norm()` tidak memvalidasi nama | tolak `.`, `..`, nama ber-`/`, dan baris baru |
| GUI mati (`n_rows: unbound variable`) setiap kali shortcut Wine mau dipromosikan | `local n_rows=… dlg_h=$((… n_rows …))` — semua kata di satu `local` di-expand sebelum assignment, `set -u` mematikan shell | pisah jadi dua `local` |
| Launcher rusak bila BASE/HOME mengandung spasi | `Exec=env WINEPREFIX=$BASE/$prefix …` tanpa kutip | `WINEPREFIX="…"` |
| Dedupe Wine salah cocok saat BASE mengandung karakter regex | `grep -q` bukan `grep -qF` | tambah `-F` |
| Installer `.msi` tidak terpasang benar | `.msi` dijalankan `wine file.msi` | `wine msiexec /i file.msi` |
| Tidak ada cara menghapus satu app | tidak ada subcommand | `apptricks remove <Name> [--yes]` + menu GUI, ikut membersihkan launcher menu & icon |
| Prefix selalu 64-bit | `WINEARCH` tidak pernah diset | `init --win32/--win64`, dicatat di `<prefix>/.apptricks-arch`, tampil di `list` dan GUI |
| Installer 32-bit gagal tanpa jalan keluar | — | GUI menawarkan recreate prefix sebagai win32 lalu install ulang |
| `setup.sh` tidak memberi tahu dukungan 32-bit | — | deteksi lib 32-bit / WoW64, tawarkan `i386` + `wine32:i386` di apt |

## 2. Bug terbuka

### B1. Kegagalan `init` diabaikan GUI
`bin/apptricks-gui:248` dan `:261` — output `apptricks init` dipipa ke `zenity --progress`, jadi exit code CLI hilang. Bila `wineboot` gagal, GUI lanjut ke install dan pesan errornya menyesatkan ("prefix hilang setelah install").
*Saran:* pakai `PIPESTATUS[0]` (atau tempfile) dan tampilkan error.

### B2. `APPTRICKS_CLI` hardcoded
`bin/apptricks-gui:10` — `~/.local/bin/apptricks`. Menjalankan `./bin/apptricks-gui` langsung dari checkout repo tidak menemukan CLI.
*Saran:* `$(dirname "$0")/apptricks` bila ada, fallback ke PATH.

### B3. Nama launcher Desktop tidak disanitasi
`bin/apptricks-gui:143` — `$HOME/Desktop/${wname}.desktop` memakai `Name=` dari Wine apa adanya. Nama mengandung `/` menulis ke path lain; nama sama saling menimpa.
*Saran:* sanitasi seperti `safe` di jalur menu.

### B4. `cleanup_wine_dupes` mencocokkan basename saja
`bin/apptricks-gui:352` — dua file `*.desktop` berbeda folder dengan nama sama bisa terhapus salah satu.
*Saran:* bandingkan path lengkap.

### B5. `find_app_icon` bisa memungut icon app lain
`bin/apptricks-gui:370` — `find "$HOME/.local/share/icons" -iname "*${lc}*"`; stem pendek (mis. `a.exe`) cocok dengan hampir semua icon.
*Saran:* minimal panjang stem, atau pakai `icotool` dari exe lebih dulu.

### B6. `du -sh` dijalankan sebelum konfirmasi impor
`bin/apptricks-gui:443` — folder sumber 50 GB membuat dialog menggantung sebelum user memutuskan.
*Saran:* tampilkan ukuran setelah user setuju, atau hitung dengan `timeout`/`du -s --exclude`.

### B7. GUI menelan semua error
Hampir semua panggilan memakai `2>/dev/null`; saat gagal tidak ada jejak. Tidak ada mode debug.
*Saran:* `APPTRICKS_DEBUG=1` → tulis ke `~/.cache/apptricks/gui.log`.

### B8. `apptricks install` CLI tidak auto-init
GUI auto-init, CLI tidak (harus `init` dulu). Padahal `init` idempoten.
*Saran:* bila prefix belum ada, jalankan init (hormati arch default win64).

### B9. Tidak ada `--version`
`VERSION` hanya hidup di `setup.sh`; `apptricks --version` dan `apptricks-gui --version` belum ada.

### B10. `uninstall.sh` tidak menghapus icon
Icon `~/.local/share/icons/hicolor/256x256/apps/apptricks-*.png` tertinggal setelah uninstall (tanpa `--purge`).
`apptricks remove` sudah membersihkannya, jadi ini hanya jalur uninstall aplikasi.

### B11. README duplikat
Dua bullet "No duplicate auto-entries" (`README.md:32` dan `:36`) — satu menjelaskan `winemenubuilder=d`, satu lagi soal launcher. Layak digabung.

### B12. Klaim `setup.sh` vs perilaku
Header `setup.sh` menyebut file user (termasuk `config`) "tidak pernah ditimpa", padahal `config` ditulis ulang setiap run. `aliases` memang tidak ditimpa.
*Saran:* perjelas teksnya, bukan ubah perilaku.

### B13. Format `apptricks list` berubah
Dulu `path/` saja; sekarang `path  arch`. Ini disengaja (fitur arch), tapi skrip yang membandingkan output persis perlu disesuaikan.

## 3. Batasan

- **Tidak ada pengujian dengan Wine/zenity sungguhan.** Seluruh alur diuji dengan stub `wine`, `wineboot`, `zenity`, `sudo`, `apt-get`, `dpkg`. Yang terbukti: cabang logika, argumen, env (`WINEARCH`), path, dan exit code — bukan hasil instalasi Windows atau tampilan dialog.
- **Tidak diuji di sesi KDE.** `kbuildsycoca`/`update-desktop-database` dipanggil tetapi efeknya tidak diperiksa.
- **Deteksi 32-bit bersifat heuristik.** Lokasi lib berbeda antar distro; build WoW64 dikenali dari `/usr/lib/wine/i386-windows` + `wine --version >= 9`. Mesin ARM/x86 non-x86_64 hanya diberi catatan.
- **Prefix lama dianggap win64.** Prefix yang dibuat sebelum fitur arch tidak punya `.apptricks-arch`; itu benar untuk apptricks versi lama (tidak pernah menyetel `WINEARCH`), tapi tidak diverifikasi untuk prefix yang dibuat manual.
- **`remove` tidak menyentuh launcher Desktop.** Disengaja (dianggap milik user); hanya launcher menu `apptricks-<Nama>*` dan icon 256×256 yang dibersihkan.
- **Retry 32-bit hanya pada kasus sempit:** `rc != 0` Dan nol shortcut baru. Installer yang "sukses" tapi aplikasinya rusak tidak terdeteksi.
- **Belum ada test otomatis** dan belum ada `shellcheck` di CI. Dua bug terakhir yang ditemukan (path traversal, `local` + `set -u`) adalah tipe yang mudah ditangkap smoke test.

## 4. Belum selesai (backlog)

1. `tests/smoke.sh` — cek `--help`, `--suggest`, `norm`, `remove`, `--purge`, `list` dengan `HOME` sementara (tanpa wine).
2. `APPTRICKS_CLI` relatif (B2) agar GUI bisa dijalankan dari repo.
3. Log debug GUI (B7).
4. `--version` (B9) + auto-init pada `install` CLI (B8).
5. Sanitasi nama launcher Desktop (B3) dan pencocokan path di `cleanup_wine_dupes` (B4).
6. `find_app_icon` lebih presisi (B5); `du -sh` ditunda (B6).
7. Bersihkan icon di `uninstall.sh` (B10); rapikan README (B11) dan teks `setup.sh` (B12).
8. `shellcheck` + smoke test di CI.

## 5. Menguji ulang dengan cepat (tanpa Wine)

```bash
# home palsu supaya tidak menyentuh data asli
export HOME="$(mktemp -d)"; mkdir -p "$HOME/.config/apptricks"
printf 'APPTRICKS_BASE="%s/prefixes"\n' "$HOME" > "$HOME/.config/apptricks/config"

./setup.sh --help                      # harus menampilkan semua opsi
bin/apptricks path ../../escape        # harus ditolak, rc=1
bin/apptricks list                     # "Belum ada prefix ..."
printf 'y\n' | ./uninstall.sh --purge  # harus menawarkan hapus prefix
```

Untuk menguji alur GUI tanpa Wine, taruh stub `wine`, `wineboot`, dan `zenity` di direktori yang
diletakkan paling depan di `PATH`; stub `zenity` cukup mengembalikan pilihan pada argumen yang
relevan (`--column=Prefix`, `--entry`, `--question`, `--column=Pilih`, `--column=Pilihan`).
