#!/usr/bin/env bash
#
# apptricks setup.sh — installer dengan progress & informasi yang jelas.
#
#   ./setup.sh                interaktif (ditanya bila perlu)
#   ./setup.sh --yes          non-interaktif, setujui semua default
#   ./setup.sh --base DIR     paksa lokasi penyimpanan prefix
#   ./setup.sh --no-desktop   lewati integrasi Dolphin/menu aplikasi
#   ./setup.sh --skip-deps    lewati cek & install dependensi (wine, zenity)
#   ./setup.sh --help         tampilkan bantuan
#
# Aman di-run ulang (idempoten): file user (aliases, config, prefix) tidak
# pernah ditimpa.
#
set -uo pipefail

VERSION="0.1.0"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL=8
STEP=0

YES=0
BASE_ARG=""
NO_DESKTOP=0
SKIP_DEPS=0
NON_TTY=0
[[ -t 0 && -t 1 ]] || NON_TTY=1

# ---------------- warna & pesan ----------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RST=$'\e[0m'; BLD=$'\e[1m'; DIM=$'\e[2m'
  GRN=$'\e[32m'; RED=$'\e[31m'; YLW=$'\e[33m'; BLU=$'\e[34m'; CYN=$'\e[36m'
else
  RST=""; BLD=""; DIM=""; GRN=""; RED=""; YLW=""; BLU=""; CYN=""
fi

step() { # step "Judul langkah"
  STEP=$((STEP + 1))
  printf '\n%s[%d/%d] %s%s\n' "$BLD$CYN" "$STEP" "$TOTAL" "$1" "$RST"
}
ok()   { printf '  %sOK%s   %s\n' "$GRN" "$RST" "$1"; }
fail() { printf '  %sGAGAL%s %s\n' "$RED" "$RST" "$1"; }
skip() { printf '  %sLEWAT%s %s\n' "$YLW" "$RST" "$1"; }
info() { printf '  %s...%s   %s\n' "$DIM" "$RST" "$1"; }
warn() { printf '  %s!%s     %s\n' "$YLW" "$RST" "$1"; }
die()  { printf '\n%sBATAL: %s%s\n' "$RED" "$1" "$RST" >&2; exit 1; }

usage() {
  sed -n '2,/^#$/p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --base) BASE_ARG="${2:?--base butuh DIR}"; shift ;;
    --base=*) BASE_ARG="${1#--base=}" ;;
    --no-desktop) NO_DESKTOP=1 ;;
    --skip-deps) SKIP_DEPS=1 ;;
    --help|-h) usage ;;
    *) die "opsi tidak dikenal: $1 (lihat --help)" ;;
  esac
  shift
done
[[ $NON_TTY -eq 1 && $YES -eq 0 ]] && YES=1 && info "bukan terminal interaktif → mode --yes otomatis"

ask() { # ask "pertanyaan" "default" → cetak jawaban
  local q="$1" d="$2" ans
  if [[ $YES -eq 1 ]]; then printf '%s' "$d"; return 0; fi
  printf '  %s?%s %s [%s]: ' "$BLU" "$RST" "$q" "$d" > /dev/tty
  IFS= read -r ans < /dev/tty || ans=""
  [[ -z "$ans" ]] && ans="$d"
  printf '%s' "$ans"
}

ask_yes_no() { # ask_yes_no "pertanyaan" default(y/n) → return 0=ya
  local q="$1" d="$2" ans
  if [[ $YES -eq 1 ]]; then [[ "$d" == "y" ]]; return $?; fi
  printf '  %s?%s %s [%s]: ' "$BLU" "$RST" "$q" "$d" > /dev/tty
  IFS= read -r ans < /dev/tty || ans=""
  [[ -z "$ans" ]] && ans="$d"
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

printf '%s  ___                __   _      __  \n' "$BLD$CYN"
printf '  / _ | ___  ___  ___/ /__(_)____/ /__\n'
printf ' / __ |/ _ \\/ _ \\/ _  / _/ / __/  __/\n'
printf '/_/ |_/ .__/ .__/\\_,_/_//_/\\__/\\__/   \n'
printf '    /_/  /_/                         %s\n' "$RST"
printf '  apptricks setup v%s — installer Wine prefix per-app\n' "$VERSION"

# ---------------- [1/8] sistem ----------------
step "Deteksi sistem"
OS_PRETTY="Linux (tak dikenal)"
[[ -f /etc/os-release ]] && OS_PRETTY="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
PM=""
if have pacman; then PM="pacman"
elif have apt-get; then PM="apt"
elif have dnf; then PM="dnf"
elif have zypper; then PM="zypper"
fi
DESKTOP="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-tidak terdeteksi}}"
info "OS      : $OS_PRETTY"
info "Desktop : $DESKTOP"
if [[ -n "$PM" ]]; then ok "package manager: $PM"; else warn "package manager tak dikenal — install dependensi harus manual"; fi

# ---------------- [2/8] dependensi ----------------
step "Cek dependensi"
if [[ $SKIP_DEPS -eq 1 ]]; then
  skip "cek dependensi (--skip-deps)"
else
  MISSING=()
  for c in wine zenity; do
    if have "$c"; then ok "$c: $(command -v "$c")"; else fail "$c: tidak ditemukan"; MISSING+=("$c"); fi
  done
  if have kbuildsycoca6 || have kbuildsycoca5; then ok "refresh menu KDE tersedia"; else skip "kbuildsycoca tak ada (bukan KDE? refresh menu dilewati nanti)"; fi
  if have update-desktop-database; then ok "update-desktop-database tersedia"; else skip "update-desktop-database tak ada (opsional)"; fi
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    if [[ -z "$PM" ]]; then
      warn "install manual paket ini: ${MISSING[*]} — lanjut tanpa mereka"
    elif ask_yes_no "install paket yang kurang (${MISSING[*]}) via $PM + sudo" "y"; then
      if ! have sudo; then
        warn "sudo tidak ada — install manual: ${MISSING[*]}"
      else
        info "menjalankan installer paket (mungkin minta password sudo)..."
        case "$PM" in
          pacman) sudo pacman -S --needed --noconfirm "${MISSING[@]}" && ok "paket terinstall" || warn "install paket gagal — lanjut, bisa install manual" ;;
          apt) sudo apt-get update && sudo apt-get install -y "${MISSING[@]}" && ok "paket terinstall" || warn "install paket gagal — lanjut, bisa install manual" ;;
          dnf) sudo dnf install -y "${MISSING[@]}" && ok "paket terinstall" || warn "install paket gagal — lanjut, bisa install manual" ;;
          zypper) sudo zypper install -y "${MISSING[@]}" && ok "paket terinstall" || warn "install paket gagal — lanjut, bisa install manual" ;;
        esac
      fi
    else
      warn "dilewati user — init/install prefix butuh wine, GUI butuh zenity"
    fi
  fi
fi

# ---------------- [3/8] lokasi prefix ----------------
step "Lokasi penyimpanan prefix (BASE)"
CONFIG_DIR="$HOME/.config/apptricks"
CONFIG_FILE="$CONFIG_DIR/config"
DEFAULT_BASE="$HOME/.local/share/apptricks/prefixes"
PROPOSED=""
PROPOSE_WHY=""
if [[ -n "$BASE_ARG" ]]; then
  PROPOSED="$BASE_ARG"; PROPOSE_WHY="dari flag --base"
elif [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  if [[ -n "${APPTRICKS_BASE:-}" ]]; then PROPOSED="$APPTRICKS_BASE"; PROPOSE_WHY="config lama ($CONFIG_FILE)"; fi
fi
if [[ -z "$PROPOSED" && -d "/mnt/data/ProgramFiles" ]]; then
  PROPOSED="/mnt/data/ProgramFiles"; PROPOSE_WHY="direktori lama ditemukan"
fi
[[ -z "$PROPOSED" ]] && PROPOSED="$DEFAULT_BASE" && PROPOSE_WHY="default"
info "usulan: $PROPOSED ($PROPOSE_WHY)"
BASE="$(ask "pakai lokasi ini" "$PROPOSED")"
[[ -z "$BASE" ]] && die "BASE tidak boleh kosong"
mkdir -p "$CONFIG_DIR" "$BASE" || die "tidak bisa membuat $BASE"
printf '# Konfigurasi apptricks (dibuat oleh setup.sh v%s)\nAPPTRICKS_BASE="%s"\n' "$VERSION" "$BASE" > "$CONFIG_FILE" \
  && ok "config ditulis: $CONFIG_FILE" || die "gagal menulis config"
ok "BASE siap: $BASE ($(ls -d "$BASE"/.*/ 2>/dev/null | grep -vc -E '/\./$|/\.\./$' || true) prefix lama terdeteksi, tidak diutak-atik)"
# migrasi alias dari generasi lama (winepf) bila ada
if [[ ! -f "$CONFIG_DIR/aliases" && -f "$HOME/.config/winepf/aliases" ]]; then
  cp "$HOME/.config/winepf/aliases" "$CONFIG_DIR/aliases" && ok "migrasi alias lama dari ~/.config/winepf/aliases"
fi

# ---------------- [4/8] binary ----------------
step "Install binary ke ~/.local/bin"
mkdir -p "$HOME/.local/bin" || die "tidak bisa membuat ~/.local/bin"
for f in "$REPO_DIR"/bin/*; do
  name="$(basename "$f")"
  if have install; then install -m755 "$f" "$HOME/.local/bin/$name"; else cp "$f" "$HOME/.local/bin/$name" && chmod 755 "$HOME/.local/bin/$name"; fi
  ok "$name → ~/.local/bin/$name"
done

# ---------------- [5/8] desktop ----------------
step "Integrasi desktop (menu + klik kanan Dolphin)"
if [[ $NO_DESKTOP -eq 1 ]]; then
  skip "integrasi desktop (--no-desktop)"
else
  mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/kio/servicemenus" || die "tidak bisa membuat direktori share"
  sed "s|__HOME__|$HOME|g" "$REPO_DIR/share/applications/apptricks-gui.desktop" > "$HOME/.local/share/applications/apptricks-gui.desktop" \
    && ok "launcher: ~/.local/share/applications/apptricks-gui.desktop"
  sed "s|__HOME__|$HOME|g" "$REPO_DIR/share/kio/servicemenus/apptricks.desktop" > "$HOME/.local/share/kio/servicemenus/apptricks.desktop" \
    && ok "service menu: ~/.local/share/kio/servicemenus/apptricks.desktop"
  # KDE menolak eksekusi .desktop user-local tanpa executable bit
  # ("not owned by root and executable flag not set").
  chmod +x "$HOME/.local/share/applications/apptricks-gui.desktop" "$HOME/.local/share/kio/servicemenus/apptricks.desktop" \
    && ok "executable bit untuk .desktop (syarat eksekusi KDE)"
  if have kbuildsycoca6; then kbuildsycoca6 >/dev/null 2>&1 && ok "refresh menu (kbuildsycoca6)" || warn "refresh kbuildsycoca6 gagal (tidak fatal)";
  elif have kbuildsycoca5; then kbuildsycoca5 >/dev/null 2>&1 && ok "refresh menu (kbuildsycoca5)" || warn "refresh kbuildsycoca5 gagal (tidak fatal)";
  else skip "refresh menu KDE (kbuildsycoca tak ada)"; fi
  if have update-desktop-database; then update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 && ok "update-desktop-database" || skip "update-desktop-database gagal (tidak fatal)"; fi
fi

# ---------------- [6/8] config user ----------------
step "Config user (~/.config/apptricks)"
if [[ -f "$CONFIG_DIR/aliases" ]]; then
  skip "aliases sudah ada — tidak ditimpa"
else
  cp "$REPO_DIR/config/aliases.example" "$CONFIG_DIR/aliases" && ok "aliases dibuat dari contoh (silakan edit)"
fi

# ---------------- [7/8] verifikasi ----------------
step "Verifikasi instalasi"
bash -n "$HOME/.local/bin/apptricks" && ok "syntax apptricks valid" || die "syntax apptricks rusak"
bash -n "$HOME/.local/bin/apptricks-gui" && ok "syntax apptricks-gui valid" || die "syntax apptricks-gui rusak"
"$HOME/.local/bin/apptricks" help >/dev/null 2>&1 && ok "apptricks help jalan" || die "apptricks tidak bisa jalan"
SUG_OUT="$("$HOME/.local/bin/apptricks-gui" --suggest "/tmp/setup_contoh2024.exe" 2>/dev/null)" || SUG_OUT=""
if [[ "$SUG_OUT" == ".Contoh2024" ]]; then ok "smoke test saran nama: $SUG_OUT"; else warn "smoke test saran nama janggal: '$SUG_OUT' (fungsi tetap terinstall)"; fi
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then ok "~/.local/bin ada di PATH"; else warn "~/.local/bin belum di PATH — tambah ke ~/.bashrc lalu buka terminal baru"; fi
have wine || warn "wine belum terinstall — 'apptricks init/install' butuh wine"
have zenity || warn "zenity belum terinstall — GUI butuh zenity (CLI tetap jalan)"

# ---------------- [8/8] ringkasan ----------------
step "Selesai"
printf '\n  %s┌─ apptricks v%s terinstall ──────────────%s\n' "$BLD$GRN" "$VERSION" "$RST"
printf '  %s│%s  binary   : ~/.local/bin/apptricks{,-gui}\n' "$BLD$GRN" "$RST"
printf '  %s│%s  BASE     : %s\n' "$BLD$GRN" "$RST" "$BASE"
printf '  %s│%s  config   : %s\n' "$BLD$GRN" "$RST" "$CONFIG_FILE"
printf '  %s└────────────────────────────────────────%s\n' "$BLD$GRN" "$RST"
printf '\n  Langkah berikutnya:\n'
printf '    apptricks init .AppKu && apptricks install .AppKu ~/Downloads/setup.exe\n'
printf '    # atau: klik kanan setup.exe di Dolphin → Install ke Prefix...\n'
printf '    # hapus total: ./uninstall.sh  (di direktori repo ini)\n\n'
