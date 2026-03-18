<div align="center">

```
██╗   ██╗██████╗ ██╗   ██╗██╗  ██╗ █████╗ ██╗     ██╗
██║   ██║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗██║     ██║
██║   ██║██████╔╝██║   ██║█████╔╝ ███████║██║     ██║
██║   ██║██╔══██╗██║   ██║██╔═██╗ ██╔══██║██║     ██║
╚██████╔╝██████╔╝╚██████╔╝██║  ██╗██║  ██║███████╗██║
 ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
```

### *Give your Ubuntu server the Kali Linux terminal aesthetic — in one command.*

---

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg?style=for-the-badge)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-1f425f.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Zsh](https://img.shields.io/badge/Shell-Zsh-F15A24?style=for-the-badge&logo=zsh&logoColor=white)](https://www.zsh.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20|%2022.04%20|%2024.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

[![Stars](https://img.shields.io/github/stars/YOUR_USERNAME/ubukali?style=for-the-badge&color=yellow&logo=github)](https://github.com/YOUR_USERNAME/ubukali/stargazers)
[![Forks](https://img.shields.io/github/forks/YOUR_USERNAME/ubukali?style=for-the-badge&color=blue&logo=github)](https://github.com/YOUR_USERNAME/ubukali/forks)
[![Issues](https://img.shields.io/github/issues/YOUR_USERNAME/ubukali?style=for-the-badge&color=red&logo=github)](https://github.com/YOUR_USERNAME/ubukali/issues)
[![Version](https://img.shields.io/badge/version-2.0-brightgreen?style=for-the-badge)](CHANGELOG.md)

</div>

---

## 📸 Preview

> **Before → After** — same Ubuntu server, one script.

| Before | After |
|:------:|:-----:|
| Plain bash, no colour | Kali-style Zsh with icons & git info |
| Basic `ls` output | `eza` with nerd font icons & git status |
| No welcome screen | Live RAM/Disk bars + neofetch on login |
| Generic prompt | Two-line Kali prompt with branch & exit code |

> 💡 **Tip:** Drop your own screenshots into the `screenshots/` folder and update the table above.

---

## ✨ What Gets Installed

<details open>
<summary><b>🐚 Shell & Prompt</b></summary>

| Component | Details |
|-----------|---------|
| **Zsh** | Replaces bash as your default shell |
| **Oh My Zsh** | Plugin & theme framework |
| **Kali two-line prompt** | `┌──(user㉿host)-[~/path] on  main` |
| **Right prompt** | Exit code `✓`/`✗` · 24h clock |
| **4 Zsh plugins** | autosuggestions · syntax-highlighting · history-substring-search · you-should-use |

</details>

<details open>
<summary><b>🛠️ Modern CLI Tools</b></summary>

| Tool | Replaces | What it does |
|------|----------|-------------|
| **eza** | `ls` | Icons, colour, git status in file listings |
| **bat** | `cat` | Syntax-highlighted file viewer |
| **btop** | `top` | Beautiful real-time resource monitor |
| **fzf** | — | Fuzzy finder (Ctrl+R history search, etc.) |
| **colordiff** | `diff` | Colour-coded file diffs |
| **neofetch** | — | System info on login |
| **lolcat / figlet / toilet** | — | Colourful banners |
| **tmux** | — | Kali-themed status bar, mouse support |

</details>

<details open>
<summary><b>🎨 Welcome Screen</b></summary>

Every login shows:
- `neofetch` system info block
- **RAM**, **Disk**, **Swap** — animated `█░` progress bars with colour thresholds (green → yellow → red)
- Uptime · Load average · Local IP · Active connections · Running processes
- Previous login info
- Failed SSH attempt count (last 24 h) — highlighted in red when > 0

</details>

<details>
<summary><b>⌨️ Aliases & Keybindings</b></summary>

```zsh
ls, ll, la, lt, ltt  → eza with icons
cat                  → bat --theme=TwoDark
top                  → btop
diff                 → colordiff
update               → sudo apt update && sudo apt upgrade -y
ports                → ss -tulnp
myip                 → curl ifconfig.me
biggest              → du sorted by size
reload               → source ~/.zshrc
```

**Keybindings (Windows Terminal compatible):**

| Key | Action |
|-----|--------|
| `↑` / `↓` | History substring search |
| `Ctrl+→` / `Ctrl+←` | Word jump |
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Home` / `End` | Line start/end |

</details>

---

## ⚡ Quick Start

### One-liner

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ubukali/main/kali-terminal-setup.sh)
```

### Or clone & run

```bash
git clone https://github.com/YOUR_USERNAME/ubukali.git
cd ubukali
bash kali-terminal-setup.sh
```

### Then activate

```bash
exec zsh
```

> **That's it.** The script handles everything — packages, Oh My Zsh, plugins, configs, permissions, and default shell change.

---

## 🖥️ Compatibility

| Ubuntu Version | Status | Notes |
|:---:|:---:|---|
| 24.04 LTS (Noble) | ✅ Fully supported | New `deb822` sources format handled |
| 22.04 LTS (Jammy) | ✅ Fully supported | `bat` symlink (`batcat→bat`) auto-created |
| 20.04 LTS (Focal) | ✅ Fully supported | `bat` symlink (`batcat→bat`) auto-created |
| Other Debian/Ubuntu | ⚠️ Best effort | May work; not tested |

| Run as | Status |
|:---:|:---:|
| `root` | ✅ |
| `sudo` user | ✅ |
| Normal user (with sudo rights) | ✅ |

---

## 🪟 Windows Terminal Font Setup

The prompt uses **Nerd Font** icons. Without the right font installed on your **Windows machine**, you'll see broken squares instead of icons.

**1. Download the font**

👉 [JetBrainsMono Nerd Font Mono](https://www.nerdfonts.com/font-downloads) — search *"JetBrainsMono"*

**2. Install on Windows**

Right-click the downloaded `.ttf` files → **Install for all users**

**3. Set in Windows Terminal**

```
Settings → Your SSH profile → Appearance → Font face
→ JetBrainsMono Nerd Font Mono
```

---

## 🕐 Timezone Configuration

The welcome screen and prompt clock use your server's timezone.  
To change it after setup:

```bash
# List available timezones
timedatectl list-timezones | grep Asia

# Set your timezone (examples)
sudo timedatectl set-timezone Asia/Kolkata
sudo timedatectl set-timezone America/New_York
sudo timedatectl set-timezone Europe/London

# Verify
timedatectl

# Reload your shell
exec zsh
```

---

## 🔧 What the Script Does — Step by Step

```
Step  1/15  ─  Enable universe apt repository
Step  2/15  ─  Update package lists
Step  3/15  ─  Install core packages  (zsh git curl wget unzip fontconfig)
Step  4/15  ─  Install enhancement tools  (neofetch btop fzf colordiff lolcat …)
Step  5/15  ─  Install bat  (with batcat→bat symlink for older Ubuntu)
Step  6/15  ─  Install eza  (falls back to GitHub binary if not in apt)
Step  7/15  ─  Install Oh My Zsh  (unattended, no shell exec)
Step  8/15  ─  Install Zsh plugins  (4 plugins via git clone)
Step  9/15  ─  Write ~/.zshrc  (prompt · plugins · aliases · keybindings)
Step 10/15  ─  Configure neofetch  (custom layout, Ubuntu small ASCII art)
Step 11/15  ─  Create welcome screen  (~/.config/welcome.sh)
Step 12/15  ─  Configure btop  (Kali colour theme)
Step 13/15  ─  Configure tmux  (Kali status bar, mouse, vi keys, Ctrl+A prefix)
Step 14/15  ─  Configure nano  (line numbers, syntax highlighting, autoindent)
Step 15/15  ─  Fix permissions + set Zsh as default shell
```

---

## 🏗️ Repository Structure

```
ubukali/
├── kali-terminal-setup.sh   # The main installer script
├── README.md                # You are here
├── LICENSE                  # MIT
├── CHANGELOG.md             # Version history
├── CONTRIBUTING.md          # How to contribute
├── screenshots/             # Add your own screenshots here
└── .github/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── PULL_REQUEST_TEMPLATE.md
```

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. 🍴 Fork the repo
2. 🌿 Create a feature branch — `git checkout -b feat/my-feature`
3. 💾 Commit your changes — `git commit -m 'feat: add my feature'`
4. 📤 Push — `git push origin feat/my-feature`
5. 🔁 Open a Pull Request

---

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

Made with ❤️ for everyone who thinks Ubuntu servers deserve better terminals.

⭐ **Star this repo if it made your terminal look awesome!** ⭐

</div>
