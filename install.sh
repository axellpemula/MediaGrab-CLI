#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

REPO="axellpemula/MediaGrab-CLI"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="mediagrab"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_CYAN="\033[36m"

info()  { echo -e "${C_CYAN}[*]${C_RESET} $1"; }
ok()    { echo -e "${C_GREEN}[+]${C_RESET} $1"; }
warn()  { echo -e "${C_YELLOW}[!]${C_RESET} $1"; }
error() { echo -e "${C_RED}[!]${C_RESET} $1" >&2; }

if [ -z "${PREFIX:-}" ] || [[ "$PREFIX" != *"com.termux"* ]]; then
  error "Installer ini khusus untuk Termux Only."
  error "Environment saat ini terdeteksi bukan Termux."
  exit 1
fi

missing_pkg=()
missing_pip=()

command -v curl >/dev/null 2>&1 || missing_pkg+=("curl")
command -v python >/dev/null 2>&1 || missing_pkg+=("python")
command -v ffmpeg >/dev/null 2>&1 || missing_pkg+=("ffmpeg")

if command -v python >/dev/null 2>&1; then
  python -c "import yt_dlp" >/dev/null 2>&1 || missing_pip+=("yt-dlp")
else
  missing_pip+=("yt-dlp")
fi

if [ ${#missing_pkg[@]} -eq 0 ] && [ ${#missing_pip[@]} -eq 0 ]; then
  :
else
  echo -e "${C_BOLD}Menyiapkan dependency yang dibutuhkan...${C_RESET}"

  if [ ${#missing_pkg[@]} -gt 0 ]; then
    info "Menginstall: ${missing_pkg[*]}"
    pkg install -y "${missing_pkg[@]}"
  fi

  if [ ${#missing_pip[@]} -gt 0 ]; then
    info "Menginstall (pip): ${missing_pip[*]}"
    pip install --upgrade "${missing_pip[@]}"
  fi

  ok "Semua dependency siap."
  echo
fi

download_url=$(curl -fsSL "$GITHUB_API" \
  | grep '"browser_download_url"' \
  | grep "$BINARY_NAME" \
  | head -n 1 \
  | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/')

if [ -z "$download_url" ]; then
  error "Tidak menemukan rilis binary MediaGrab di GitHub."
  error "Pastikan sudah ada release dengan asset bernama '${BINARY_NAME}' di:"
  error "https://github.com/${REPO}/releases"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
target_path="${INSTALL_DIR}/${BINARY_NAME}"

info "Mengunduh MediaGrab CLI..."
curl -fsSL "$download_url" -o "$target_path"
chmod +x "$target_path"

shell_rc="$HOME/.bashrc"
if [ -n "${SHELL:-}" ] && [[ "$SHELL" == *"zsh"* ]]; then
  shell_rc="$HOME/.zshrc"
fi

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
  warn "PATH baru ditambahkan ke $(basename "$shell_rc")."
  warn "Jalankan 'source $shell_rc' atau buka ulang Termux supaya command 'mediagrab' langsung dikenali."
fi

echo
ok "MediaGrab CLI berhasil diinstall!"
echo -e "${C_DIM}    Lokasi: ${target_path}${C_RESET}"
echo
echo -e "${C_BOLD}Jalankan dengan:${C_RESET}"
echo -e "${C_CYAN}    mediagrab${C_RESET}"
