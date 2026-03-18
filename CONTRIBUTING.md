# Contributing to ubukali

First off — thank you for taking the time to contribute! 🎉

---

## 🐛 Reporting Bugs

Before opening a bug report, please:

1. **Check existing issues** — someone may have already reported it.
2. **Test on a clean machine** if possible, to rule out environment-specific causes.

When opening an issue, include:

- Ubuntu version (`lsb_release -a`)
- How you ran the script (`root` / `sudo` / normal user)
- The full error message or unexpected output
- Steps to reproduce

---

## 💡 Suggesting Features

Open an issue using the **Feature Request** template. Describe:

- What problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

---

## 🔁 Submitting a Pull Request

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/ubukali.git
cd ubukali
```

### Workflow

```bash
# Create a branch
git checkout -b feat/your-feature-name   # for features
git checkout -b fix/short-bug-description  # for fixes

# Make your changes …

# Test on a fresh Ubuntu VM/container
bash kali-terminal-setup.sh

# Commit using conventional commits
git commit -m "feat: add support for Debian"
git commit -m "fix: correct bat symlink on 22.04"
git commit -m "docs: update timezone instructions"

# Push
git push origin feat/your-feature-name
```

Then open a Pull Request against `main`.

---

## 📐 Code Style

- **4-space indent** for bash functions
- Keep lines under **100 characters**
- Use the existing helper functions: `step()`, `ok()`, `info()`, `warn()`, `die()`
- Add a `# FIX / NOTE:` comment when patching a subtle behaviour
- Test with `bash -n kali-terminal-setup.sh` (syntax check) before pushing
- Every new feature should have a matching entry in `CHANGELOG.md`

---

## 🏷️ Commit Message Convention

```
<type>: <short description>

Types:
  feat      New feature
  fix       Bug fix
  docs      Documentation only
  style     Formatting, no logic change
  refactor  Code restructure, no behaviour change
  test      Adding tests
  chore     Build / CI / tooling
```

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
