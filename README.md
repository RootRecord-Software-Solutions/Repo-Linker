<div align="center">

# 🔗 Repo Linker

**Right-click any folder. Paste a GitHub link. Pick an account. Done.**

Link GitHub repos into your project as git submodules, straight from the Files app on Linux.<br>
No terminal, no remembering `git submodule add`, no pushing with the wrong account.

![Platform](https://img.shields.io/badge/platform-Linux%20%C2%B7%20GNOME%20Files-informational)
![Shell](https://img.shields.io/badge/made%20with-bash-4EAA25)
![License](https://img.shields.io/badge/license-MIT-blue)
![Price](https://img.shields.io/badge/price-free-brightgreen)

</div>

---

## ✨ What it does

Right-click a folder → **Scripts → Repo Linker**, and it figures out what you need:

| The folder is… | The repo is… | Repo Linker… |
| --- | --- | --- |
| 📂 Empty | Has commits | Clones it in and links it as a submodule |
| 📂 Empty | Brand new | Adds a README + safe `.gitignore`, pushes, links it |
| 📁 Full of files | Brand new | **First-time push**: turns your folder into the repo's first commit |
| 🔗 Already linked | — | Shows a **settings window**: repo, push account, commit identity, branch, changes, last commit |

## 🧑‍🤝‍🧑 Multiple GitHub accounts, no mix-ups

Have a personal account, a work account and a bot account? Pick which one pushes each repo from a simple list. Repo Linker sets the push remote to that account's SSH key and sets the commit name and email for that repo only.

## 🛡️ Safe by default

- Audio files, `.env` files, private keys and anything named like a token are always ignored.
- It never overwrites: if your folder **and** the repo both have content, it stops and tells you.
- It only works inside the root repo you configured.
- It asks before a first-time push, showing how many files and how big.
- Uses your SSH keys. No tokens are stored, nothing expires.

## 📦 Install

You need Linux with GNOME Files (Nautilus), `git`, `zenity`, and SSH keys set up for GitHub.

```bash
sudo apt install git zenity
git clone https://github.com/RootRecord-Software-Solutions/Repo-Linker.git
cd Repo-Linker && ./install.sh
```

Then open `~/.config/repo-linker/config` and set your root repo and accounts:

```bash
ROOT="$HOME/Projects"

ACCOUNTS=(
  "Me|github.com|Your Name|you@example.com"
  "Work|github-work|Your Name|you@work.example"
)
```

Each account is `Label|ssh-host|commit name|commit email`, where `ssh-host` is a `Host` from your `~/.ssh/config`:

```sshconfig
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

## 🚀 Use it

1. Right-click a folder inside your root repo.
2. **Scripts → Repo Linker**.
3. Paste the GitHub link (`https://…`, `…/tree/main` or `git@…` all work).
4. Pick the account.

That's it. The repo is linked, committed and pushed in your root repo.

## ⚙️ Extras

- **`AFTER_LINK`** in the config runs any command after a link, with `$REPO_DIR` and `$REPO_SLUG` set. Use it to update a sync list, notify yourself, anything.
- If something fails, details are saved to `~/.local/state/repo-linker/last-error.log`.

> 💡 Tip: don't run `git submodule sync` afterward. It resets each submodule's push remote back to the HTTPS link from `.gitmodules`.

## 📄 License

MIT. Free to use, change and share.

<div align="center">
<sub>Made with ☕ on the Big Island by <b>Rootrecord Software Systems</b></sub>
</div>
