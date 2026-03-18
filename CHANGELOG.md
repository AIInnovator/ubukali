# Changelog

All notable changes to **ubukali** will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] — 2026-03-19

### 🐛 Fixed
- **RAM bar 5910% overflow** — Switched RAM percentage calculation from `free`
  (unreliable column layout on newer procps) to `/proc/meminfo` arithmetic.
  Added a `pct > 100` clamp in `bar_fill()` as a second-line safety net.
- **`integer expression expected: 0\n0` error in welcome screen** — `grep -c`
  exits with code `1` on zero matches, firing the `|| echo 0` fallback and
  producing a double-zero `0\n0` string. Replaced with `grep | wc -l` which
  always exits `0` and always outputs a clean integer.

### ✨ Added
- **Timezone tip** in the final summary box after install completes.
- `bar_fill()` now defensively clamps `pct` to `[0, 100]` regardless of input.

### 🔧 Changed
- Script version bumped to `v2.0` (Bug-Fixed edition).

---

## [1.0.0] — 2026-03-01

### 🎉 Initial Release

- 15-step automated installer for Kali-style terminal on Ubuntu 20.04 / 22.04 / 24.04
- Zsh + Oh My Zsh with 4 plugins (autosuggestions, syntax-highlighting,
  history-substring-search, you-should-use)
- Kali two-line prompt with git branch, exit code indicator, right-side clock
- `eza` (modern `ls` with icons) — apt or GitHub binary fallback
- `bat` (syntax-highlighted `cat`) — `batcat→bat` symlink for Ubuntu ≤ 22.04
- `btop` with custom Kali colour theme
- Welcome screen: neofetch + RAM/Disk/Swap bars + login & SSH stats
- tmux Kali status bar configuration
- nano with line numbers, syntax highlighting, autoindent
- Smart user detection: works as `root`, `sudo`, or normal user
- Per-package apt fallback so one missing package never kills the whole script
- Ubuntu 24.04 `deb822` sources format support
