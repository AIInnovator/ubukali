#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         KALI-STYLE TERMINAL SETUP FOR UBUNTU SERVER         ║
# ║              Universal Edition  v2.0  (Bug-Fixed)           ║
# ║   Supports: Ubuntu 20.04 / 22.04 / 24.04 | root or user    ║
# ╚══════════════════════════════════════════════════════════════╝
# Usage:
#   As root:        bash kali-terminal-setup.sh
#   As normal user: bash kali-terminal-setup.sh
#   With sudo:      sudo bash kali-terminal-setup.sh

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'
B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'
N='\033[0m';    DIM='\033[2m'

# ── Helpers ───────────────────────────────────────────────────────
step()  { echo -e "\n${C}┌──[${W}*${C}]${N} ${W}$*${N}"; }
ok()    { echo -e "${G}└──[${W}✓${G}] Done${N}"; }
info()  { echo -e "    ${DIM}$*${N}"; }
warn()  { echo -e "    ${Y}[!] $*${N}"; }
die()   { echo -e "\n${R}[✗] $*${N}\n"; exit 1; }

# ── Run as target user (works root OR normal user) ────────────────
# FIX BUG 4: don't blindly call sudo -u when script isn't root
run_as_user() {
  if [ "$EUID" -eq 0 ] && [ "$TUSER" != "root" ]; then
    sudo -u "$TUSER" "$@"
  else
    "$@"
  fi
}

# ── apt wrapper: never lets ONE package kill whole script ─────────
# FIX BUG 5: set -e + apt failures = crash. Retry per-package instead
apt_install() {
  local pkgs=("$@")
  if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pkgs[@]}" 2>/dev/null; then
    return 0
  fi
  warn "Bulk install had issues; retrying one by one..."
  for pkg in "${pkgs[@]}"; do
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" 2>/dev/null \
      && info "  Installed : $pkg" \
      || warn "  Skipped   : $pkg (not available on this Ubuntu version)"
  done
}

# ── Ubuntu version ────────────────────────────────────────────────
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null \
  || grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release \
  || echo "0")
UBUNTU_MAJOR=$(echo "$UBUNTU_VERSION" | cut -d. -f1)

# ── Sanity checks ─────────────────────────────────────────────────
grep -qi ubuntu /etc/os-release 2>/dev/null \
  || die "This script is for Ubuntu only."

if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  die "Need root or sudo access.\nRun: sudo bash $0"
fi

# ── Detect target user ────────────────────────────────────────────
# Priority: SUDO_USER > current user if non-root > first real user > root
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  TUSER="$SUDO_USER"
  THOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [ "$EUID" -ne 0 ]; then
  TUSER="$USER"
  THOME="$HOME"
else
  # Pure root session — find first human account (UID 1000-65533)
  FIRST_USER=$(getent passwd \
    | awk -F: '$3>=1000 && $3<65534 && $7!~/nologin|false/{print $1; exit}')
  if [ -n "$FIRST_USER" ]; then
    TUSER="$FIRST_USER"
    THOME=$(getent passwd "$FIRST_USER" | cut -d: -f6)
    warn "Running as root with no SUDO_USER — configuring for: $TUSER"
  else
    TUSER="root"
    THOME="/root"
    warn "No non-root user found — configuring for root."
  fi
fi

[ -d "$THOME" ] || die "Home '$THOME' does not exist for user '$TUSER'."
ZSH_CUSTOM="$THOME/.oh-my-zsh/custom"

# ── Banner ────────────────────────────────────────────────────────
clear
echo -e "${C}"
cat << 'BANNER'
 ██╗  ██╗ █████╗ ██╗     ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗
 ██║ ██╔╝██╔══██╗██║     ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
 █████╔╝ ███████║██║     ██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝
 ██╔═██╗ ██╔══██║██║     ██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
 ██║  ██╗██║  ██║███████╗██║    ███████║███████╗   ██║   ╚██████╔╝██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝   ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
BANNER
echo -e "${N}${DIM}  Kali-Style Terminal Setup — Universal v2.0 (Bug-Fixed)${N}"
echo -e "${C}  ────────────────────────────────────────────────────────────${N}"
echo ""
info "Ubuntu version  : ${W}${UBUNTU_VERSION}"
info "Configuring for : ${W}${TUSER}"
info "Home directory  : ${W}${THOME}"
info "Script runs as  : ${W}$(whoami) (EUID=${EUID})"
echo ""

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 1 — Enable universe repo                              ║
# ╚══════════════════════════════════════════════════════════════╝
# FIX BUG 6: Linode fresh images sometimes ship without universe
step "Step 1/15 — Enabling universe repository..."
if [ "$UBUNTU_MAJOR" -ge 24 ]; then
  # Ubuntu 24.04+ uses new deb822 format
  SOURCES_FILE="/etc/apt/sources.list.d/ubuntu.sources"
  if [ -f "$SOURCES_FILE" ] && ! grep -q "universe" "$SOURCES_FILE"; then
    sed -i 's/^Components: main$/Components: main universe restricted multiverse/' \
      "$SOURCES_FILE"
    info "universe added to ubuntu.sources"
  else
    info "universe already enabled (24.04+)"
  fi
else
  # Ubuntu 20.04 / 22.04
  add-apt-repository universe -y -q 2>/dev/null || true
  info "universe repo ensured (20.04/22.04)"
fi
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 2 — Update package lists                              ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 2/15 — Updating package lists..."
apt-get update -qq
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 3 — Required core packages                            ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 3/15 — Installing required core packages..."
apt_install zsh git curl wget unzip fontconfig
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 4 — Optional enhancement packages                     ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 4/15 — Installing optional enhancement tools..."
apt_install neofetch btop fzf colordiff lolcat figlet toilet tree jq tmux ncdu
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 5 — bat (syntax-highlighted cat)                      ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 5/15 — Installing bat..."
# FIX BUG 3: Ubuntu 20.04/22.04 installs bat binary as 'batcat'
#            Ubuntu 24.04 installs it correctly as 'bat'
#            We normalise everything to 'bat' via symlink if needed
BAT_BIN=""
apt_install bat
if command -v bat &>/dev/null; then
  BAT_BIN="bat"
  info "bat binary: bat"
elif command -v batcat &>/dev/null; then
  BAT_BIN="batcat"
  info "bat binary: batcat (Ubuntu ≤22.04)"
  # Create symlink so 'bat' works universally
  ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>/dev/null && {
    BAT_BIN="bat"
    info "Created symlink: batcat → /usr/local/bin/bat"
  } || warn "Symlink failed; will use 'batcat' in aliases"
fi
[ -z "$BAT_BIN" ] && warn "bat not available; cat aliases will be plain."
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 6 — eza (modern ls)                                   ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 6/15 — Installing eza..."
EZA_OK=false
apt_install eza
if command -v eza &>/dev/null; then
  EZA_OK=true
  info "eza installed from apt"
else
  warn "eza not in apt; trying GitHub binary release..."
  EZA_URL=$(curl -fsSL --connect-timeout 10 \
    "https://api.github.com/repos/eza-community/eza/releases/latest" 2>/dev/null \
    | grep -o '"browser_download_url": *"[^"]*eza_x86_64-unknown-linux-gnu\.tar\.gz"' \
    | grep -o 'https://[^"]*' | head -1)
  if [ -n "$EZA_URL" ]; then
    wget -q --timeout=30 "$EZA_URL" -O /tmp/eza.tar.gz \
      && tar -xzf /tmp/eza.tar.gz -C /tmp/ \
      && mv /tmp/eza /usr/local/bin/eza \
      && chmod +x /usr/local/bin/eza \
      && EZA_OK=true \
      && info "eza installed from GitHub binary" \
      || warn "eza GitHub install failed; falling back to ls aliases."
    rm -f /tmp/eza.tar.gz /tmp/eza 2>/dev/null || true
  else
    warn "Could not resolve eza release URL; using plain ls aliases."
  fi
fi
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 7 — Oh My Zsh                                         ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 7/15 — Installing Oh My Zsh for ${TUSER}..."
if [ ! -d "$THOME/.oh-my-zsh" ]; then
  # RUNZSH=no  → don't exec zsh at end (would hang/break the script)
  # CHSH=no    → we handle chsh ourselves in Step 15
  run_as_user env HOME="$THOME" RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  info "Oh My Zsh installed"
else
  warn "Oh My Zsh already exists — pulling latest updates..."
  run_as_user git -C "$THOME/.oh-my-zsh" pull -q 2>/dev/null || true
fi
# Ensure custom dirs exist before plugin clones
run_as_user mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 8 — Zsh plugins                                       ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 8/15 — Installing Zsh plugins..."

install_plugin() {
  local repo="$1"
  # folder name = basename of the repo (must match what's in plugins=() array)
  local name
  name=$(basename "$repo")
  local dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    run_as_user git clone -q --depth=1 \
      "https://github.com/$repo" "$dest" \
      && info "Installed : $name" \
      || warn "Failed    : $repo — skipping"
  else
    warn "Already present: $name"
  fi
}

install_plugin "zsh-users/zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting"
install_plugin "zsh-users/zsh-history-substring-search"
# FIX BUG 1: clones into folder "zsh-you-should-use"
#            plugins=() array must use the SAME name below
install_plugin "MichaelAquilina/zsh-you-should-use"
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 9 — Build .zshrc                                      ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 9/15 — Writing .zshrc..."

# Build alias blocks based on what actually installed
if $EZA_OK; then
LS_BLOCK='alias ls="eza --icons --color=always --group-directories-first"
alias ll="eza -lah --icons --color=always --group-directories-first --git --time-style=long-iso"
alias la="eza -a --icons --color=always --group-directories-first"
alias lt="eza --tree --icons --level=2 --color=always"
alias ltt="eza --tree --icons --level=3 --color=always"'
else
LS_BLOCK='alias ls="ls --color=auto --group-directories-first"
alias ll="ls -lahF --color=auto"
alias la="ls -A --color=auto"'
fi

if [ -n "$BAT_BIN" ]; then
BAT_BLOCK="alias cat=\"${BAT_BIN} --paging=never --theme=TwoDark\"
export MANPAGER=\"sh -c 'col -bx | ${BAT_BIN} -l man -p --theme=TwoDark'\""
else
BAT_BLOCK='# bat not installed — using plain cat'
fi

cat > "$THOME/.zshrc" << ZSHRC
# ╔══════════════════════════════════════════════╗
# ║     Kali-Style Zsh Config — Universal v2.0   ║
# ╚══════════════════════════════════════════════╝

export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""   # We define a custom prompt below

# ── History ───────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
HIST_STAMPS="yyyy-mm-dd"
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY EXTENDED_HISTORY

# ── Options ───────────────────────────────────────────────────────
setopt AUTO_CD CORRECT COMPLETE_ALIASES GLOB_DOTS

# ── Plugins ───────────────────────────────────────────────────────
# NOTE: plugin names MUST match the cloned folder names exactly
# FIX BUG 1: "zsh-you-should-use" not "you-should-use"
plugins=(
  git
  sudo
  colored-man-pages
  command-not-found
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  zsh-you-should-use
)

source \$ZSH/oh-my-zsh.sh

# ── Kali-Style Prompt ─────────────────────────────────────────────
# Line 1:  ┌──(user㉿host)-[~/path] on  main
# Line 2:  └─$  (└─# for root)
autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*'     enable git
zstyle ':vcs_info:git:*' formats       ' on %F{214}%B %b%b%f'
zstyle ':vcs_info:git:*' actionformats ' on %F{214}%B %b%b%f %F{red}(%a)%f'

# FIX BUG 2: correct function name is "vcs_info", NOT "precmd_vcs_info"
precmd_functions+=(vcs_info)

PROMPT='%F{cyan}┌──(%f%B%F{green}%n%f%F{cyan}㉿%f%F{39}%m%f%b%F{cyan})%f%F{cyan}-[%f%B%F{white}%~%b%f%F{cyan}]%f\${vcs_info_msg_0_}
%F{cyan}└─%f%B%(!.%F{red}#%f.%F{cyan}\$%f)%b '

# Right: exit status icon + 24h clock
RPROMPT='%(?.%F{green}✓%f.%F{red}✗ %?%f) %F{cyan}[%f%F{white}%T%f%F{cyan}]%f'

# ── Syntax Highlighting Colours ───────────────────────────────────
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta,bold'

# ── Autosuggestions ───────────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ── fzf (Kali palette) ────────────────────────────────────────────
export FZF_DEFAULT_OPTS='
  --color=fg:#c8d3f5,bg:#1a1b26,hl:#00d7ff
  --color=fg+:#c8d3f5,bg+:#1e2030,hl+:#00d7ff
  --color=info:#82aaff,prompt:#00d7ff,pointer:#00d7ff
  --color=marker:#c3e88d,spinner:#c3e88d,header:#82aaff
  --border=rounded --prompt=" " --pointer="➜"
  --layout=reverse --height=40%'
export FZF_CTRL_R_OPTS="--prompt='  History > '"

# ── ls (eza or plain) ─────────────────────────────────────────────
${LS_BLOCK}

# ── cat / bat ─────────────────────────────────────────────────────
${BAT_BLOCK}

# ── General aliases ───────────────────────────────────────────────
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='colordiff 2>/dev/null || diff'
alias top='btop 2>/dev/null || top'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias df='df -h'
alias du='du -sh *'
alias free='free -h'
alias c='clear'
alias cls='clear'
alias h='history | tail -50'
alias j='jobs -l'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias localip='ip -4 addr | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | grep -v 127'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias search='apt search'
alias logs='sudo journalctl -f'
alias syslog='sudo tail -f /var/log/syslog'
alias listening='ss -tlnp'
alias biggest='du -sh * | sort -rh | head -20'
alias reload='source ~/.zshrc && echo "  Config reloaded"'
alias edit='\${EDITOR:-nano} ~/.zshrc'
alias path='echo \$PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d  %H:%M:%S"'

# ── Key Bindings (Windows Terminal compatible) ────────────────────
bindkey '^[[A'    history-substring-search-up
bindkey '^[[B'    history-substring-search-down
bindkey '^[OA'    history-substring-search-up      # Windows Terminal alt
bindkey '^[OB'    history-substring-search-down
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
bindkey '^[.'     insert-last-word
bindkey '^R'      history-incremental-search-backward

# ── Environment ───────────────────────────────────────────────────
export PATH="\$HOME/.local/bin:/usr/local/bin:\$PATH"
export EDITOR="nano"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── Welcome screen ────────────────────────────────────────────────
[ -f "\$HOME/.config/welcome.sh" ] && source "\$HOME/.config/welcome.sh"
ZSHRC

info ".zshrc written"
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 10 — neofetch config                                  ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 10/15 — Configuring neofetch..."
run_as_user mkdir -p "$THOME/.config/neofetch"
cat > "$THOME/.config/neofetch/config.conf" << 'NEOCONF'
print_info() {
    info title
    info underline
    info "  OS      " distro
    info "  Kernel  " kernel
    info "  Uptime  " uptime
    info "  Packages" packages
    info "  Shell   " shell
    info "  Terminal" term
    info "  CPU     " cpu
    info "  Memory  " memory
    info "  Disk    " disk
    info cols
}
title_fqdn="off"
distro_shorthand="off"
os_arch="on"
kernel_shorthand="on"
uptime_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"
memory_percent="on"
memory_unit="gib"
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"
packages_format="tiny"
colors=(6 6 6 6 6 6)
bold="on"
underline_enabled="on"
underline_char="─"
separator=" ➜  "
image_backend="ascii"
ascii_distro="Ubuntu_small"
ascii_colors=(6 6 6 6 6 6)
ascii_bold="on"
NEOCONF
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 11 — Welcome screen                                   ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 11/15 — Creating welcome screen..."
run_as_user mkdir -p "$THOME/.config"
cat > "$THOME/.config/welcome.sh" << 'WELCOME'
#!/usr/bin/env zsh
# ── Welcome Screen ────────────────────────────────────────────────
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'
R='\033[1;31m'; B='\033[1;34m'; W='\033[1;37m'
D='\033[2m'; N='\033[0m'

divider() { echo -e "${C}  ─────────────────────────────────────────────────────${N}"; }

neofetch 2>/dev/null || true
divider

# ── Live system stats ─────────────────────────────────────────────
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_PCT=$(df / | awk 'NR==2{print $5}')
DISK_NUM=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
RAM_USED=$(free -h | awk '/^Mem:/{print $3}')
RAM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
RAM_PCT=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{if(t>0)printf "%.0f",(t-a)/t*100;else print 0}' /proc/meminfo)
SWAP_USED=$(free -h | awk '/^Swap:/{print $3}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/{print $2}')
UPTIME_STR=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')
LOCAL_IP=$(ip -4 addr show scope global 2>/dev/null \
  | awk '/inet/{print $2}' | cut -d/ -f1 | head -1 || echo "N/A")
PROCESSES=$(ps aux --no-headers 2>/dev/null | wc -l || echo "?")
CONNECTIONS=$(ss -tnp 2>/dev/null | grep -c ESTAB || echo 0)

# Coloured progress bar
bar_fill() {
  local pct=$1
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0   ] && pct=0
  local len=20 filled=$(( pct * 20 / 100 )) bar=""
  local empty=$(( 20 - filled ))
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty;  i++)); do bar+="░"; done
  if   [ "$pct" -ge 90 ]; then echo -e "${R}${bar}${N}"
  elif [ "$pct" -ge 70 ]; then echo -e "${Y}${bar}${N}"
  else echo -e "${G}${bar}${N}"; fi
}

printf "  ${C}%-12s${N}  %s  ${W}%s${N}/${W}%s${N} ${D}(%s%%)${N}\n" \
  "  RAM"  "$(bar_fill "$RAM_PCT")"  "$RAM_USED"  "$RAM_TOTAL"  "$RAM_PCT"
printf "  ${C}%-12s${N}  %s  ${W}%s${N}/${W}%s${N} ${D}(%s)${N}\n" \
  "  DISK" "$(bar_fill "$DISK_NUM")" "$DISK_USED" "$DISK_TOTAL" "$DISK_PCT"
printf "  ${C}%-12s${N}  ${W}%s${N} / ${W}%s${N}\n" "  SWAP" "$SWAP_USED" "$SWAP_TOTAL"

divider

printf "  ${B}%-12s${N}  ${W}%s${N}\n" "  UPTIME"   "$UPTIME_STR"
printf "  ${B}%-12s${N}  ${W}%s${N}\n" "  LOAD"     "$LOAD_AVG"
printf "  ${B}%-12s${N}  ${W}%s${N}\n" "  LOCAL IP" "$LOCAL_IP"
printf "  ${B}%-12s${N}  ${W}%s connections  ·  %s processes${N}\n" \
  "  SESSION" "$CONNECTIONS" "$PROCESSES"

divider

# Last login (skip current/first line, show previous)
LAST=$(last -n 3 "$USER" 2>/dev/null | awk 'NR==2{
  ip=$3; d=$4" "$5" "$6
  if(ip~/^[0-9]/) printf "from %s on %s", ip, d
  else printf "local on %s", d
}')
[ -n "$LAST" ] && \
  printf "  ${Y}%-12s${N}  ${W}%s${N}\n" "  LAST LOGIN" "$LAST"

# Failed SSH attempts in last 24h
FAILED=$(journalctl _SYSTEMD_UNIT=sshd.service --since "24h ago" 2>/dev/null \
  | grep "Failed password" | wc -l)
FAILED=${FAILED:-0}
[ "$FAILED" -gt 0 ] && \
  printf "  ${R}%-12s${N}  ${W}%s failed SSH login attempts (last 24h)${N}\n" \
    "  ⚠  SSH" "$FAILED"

divider
echo ""
WELCOME
chmod +x "$THOME/.config/welcome.sh"
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 12 — btop                                             ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 12/15 — Configuring btop..."
run_as_user mkdir -p "$THOME/.config/btop/themes"
cat > "$THOME/.config/btop/btop.conf" << 'BTOPCONF'
color_theme = "kali"
theme_background = True
truecolor = True
graph_symbol = "braille"
shown_boxes = "cpu mem net proc"
update_ms = 1000
proc_sorting = "cpu lazy"
cpu_graph_upper = "total"
cpu_graph_lower = "user"
mem_graphs = True
net_auto = True
BTOPCONF
cat > "$THOME/.config/btop/themes/kali.theme" << 'BTOPTHEME'
theme[main_bg]="#1a1b26"
theme[main_fg]="#c8d3f5"
theme[title]="#00d7ff"
theme[hi_fg]="#00d7ff"
theme[selected_bg]="#1e2030"
theme[selected_fg]="#00d7ff"
theme[inactive_fg]="#4a5278"
theme[graph_text]="#c8d3f5"
theme[meter_bg]="#1e2030"
theme[cpu_box]="#00d7ff"
theme[mem_box]="#82aaff"
theme[net_box]="#c3e88d"
theme[proc_box]="#ff757f"
theme[div_line]="#2a2b3d"
theme[temp_start]="#c3e88d"
theme[temp_mid]="#ffc777"
theme[temp_end]="#ff757f"
theme[cpu_start]="#00d7ff"
theme[cpu_mid]="#82aaff"
theme[cpu_end]="#ff757f"
theme[free_start]="#c3e88d"
theme[free_mid]="#82aaff"
theme[free_end]="#ff757f"
theme[used_start]="#82aaff"
theme[used_mid]="#ffc777"
theme[used_end]="#ff757f"
theme[download_start]="#c3e88d"
theme[download_mid]="#82aaff"
theme[download_end]="#ff757f"
theme[upload_start]="#c3e88d"
theme[upload_mid]="#ffc777"
theme[upload_end]="#ff757f"
BTOPTHEME
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 13 — tmux                                             ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 13/15 — Configuring tmux..."
cat > "$THOME/.tmux.conf" << 'TMUXCONF'
set -g default-terminal "screen-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g prefix C-a
unbind C-b
bind C-a send-prefix
set -g mouse on
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -sg escape-time 0
# Status bar
set -g status on
set -g status-interval 5
set -g status-position bottom
set -g status-style "bg=#1a1b26,fg=#c8d3f5"
set -g status-left-length 40
set -g status-right-length 80
set -g status-left "#[bg=#00d7ff,fg=#1a1b26,bold] ▶ #S #[bg=#1a1b26,fg=#00d7ff] "
set -g status-right "#[fg=#82aaff] %Y-%m-%d #[fg=#00d7ff,bold]%H:%M #[bg=#00d7ff,fg=#1a1b26,bold] #h "
setw -g window-status-format         "#[fg=#4a5278] #I:#W "
setw -g window-status-current-format "#[bg=#1e2030,fg=#00d7ff,bold] #I:#W #[bg=#1a1b26]"
set -g pane-border-style        "fg=#2a2b3d"
set -g pane-active-border-style "fg=#00d7ff"
# Splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "Config reloaded"
# Vi copy mode
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
TMUXCONF
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 14 — nano                                             ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 14/15 — Configuring nano..."
cat > "$THOME/.nanorc" << 'NANORC'
set autoindent
set tabsize 4
set tabstospaces
set linenumbers
set numbercolor cyan,black
set smooth
set mouse
set boldtext
include "/usr/share/nano/*.nanorc"
NANORC
ok

# ╔══════════════════════════════════════════════════════════════╗
# ║  STEP 15 — Finalise: permissions + default shell            ║
# ╚══════════════════════════════════════════════════════════════╝
step "Step 15/15 — Fixing permissions and setting Zsh as default shell..."

# Fix ownership for everything we wrote
chown -R "$TUSER:$TUSER" \
  "$THOME/.oh-my-zsh" \
  "$THOME/.zshrc" \
  "$THOME/.config" \
  "$THOME/.tmux.conf" \
  "$THOME/.nanorc" 2>/dev/null || true

touch "$THOME/.zsh_history"
chown "$TUSER:$TUSER" "$THOME/.zsh_history"
chmod 600 "$THOME/.zsh_history"

# Set Zsh as default shell
ZSH_PATH=$(command -v zsh)
CURRENT_SHELL=$(getent passwd "$TUSER" | cut -d: -f7)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  # Ensure zsh is listed in /etc/shells (required for chsh)
  grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
  chsh -s "$ZSH_PATH" "$TUSER" \
    && info "Default shell → $ZSH_PATH" \
    || warn "chsh failed. Run manually: chsh -s $ZSH_PATH $TUSER"
else
  warn "Zsh is already the default shell for $TUSER"
fi
ok

# ── Final Summary ─────────────────────────────────────────────────
echo ""
echo -e "${C}╔══════════════════════════════════════════════════════════════════╗${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}║${N}   ${G}✓  All 15 steps complete! Your terminal is now Kali-style.${N}   ${C}║${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}╠══════════════════════════════════════════════════════════════════╣${N}"
echo -e "${C}║${N}  ${Y}⚠  ACTION REQUIRED on your Windows machine:${N}                   ${C}║${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}║${N}  1. Download: ${B}https://www.nerdfonts.com/font-downloads${N}          ${C}║${N}"
echo -e "${C}║${N}     Install: ${W}JetBrainsMono Nerd Font Mono${N}                       ${C}║${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}║${N}  2. Windows Terminal → Settings → Your SSH profile              ${C}║${N}"
echo -e "${C}║${N}     → Appearance → Font face                                    ${C}║${N}"
echo -e "${C}║${N}     → Set to: ${W}JetBrainsMono Nerd Font Mono${N}                     ${C}║${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}╠══════════════════════════════════════════════════════════════════╣${N}"
echo -e "${C}║${N}  ${C}What got installed:${N}                                             ${C}║${N}"
echo -e "${C}║${N}   ${G}•${N}  Zsh + Oh My Zsh + 4 plugins (autosuggestions, highlight,  ${C}║${N}"
echo -e "${C}║${N}      history-search, you-should-use)                              ${C}║${N}"
echo -e "${C}║${N}   ${G}•${N}  Kali two-line prompt — git branch, exit code ✓/✗, clock   ${C}║${N}"
echo -e "${C}║${N}   ${G}•${N}  eza (ls+icons), bat (cat), btop (top), fzf, colordiff     ${C}║${N}"
echo -e "${C}║${N}   ${G}•${N}  Welcome screen: neofetch + RAM/Disk bars + login info     ${C}║${N}"
echo -e "${C}║${N}   ${G}•${N}  tmux Kali status bar | nano line numbers + highlighting   ${C}║${N}"
echo -e "${C}║${N}                                                                  ${C}║${N}"
echo -e "${C}╠══════════════════════════════════════════════════════════════════╣${N}"
echo -e "${C}║${N}  ${C}Activate now:${N}  ${W}exec zsh${N}                                      ${C}║${N}"
echo -e "${C}╠══════════════════════════════════════════════════════════════════╣${N}"
echo -e "${C}║${N}  ${Y}⏰ Timezone tip:${N}                                                ${C}║${N}"
echo -e "${C}║${N}     To change timezone:                                          ${C}║${N}"
echo -e "${C}║${N}     ${W}sudo timedatectl set-timezone Asia/Kolkata${N}                 ${C}║${N}"
echo -e "${C}║${N}     Then reload your shell: ${W}exec zsh${N}                            ${C}║${N}"
echo -e "${C}╚══════════════════════════════════════════════════════════════════╝${N}"
echo ""
