# home-lab

Provisioning repo that makes every device (Mac, RHEL, Raspberry Pi) look and
behave the same: zsh + oh-my-zsh, common CLI tools, git identity, Podman +
podman-compose, and Tailscale.

Works on **macOS**, **RHEL 10** (and Rocky/Alma/Fedora), and **Debian /
Raspberry Pi OS**. Everything is **idempotent** — re-run any time.

## Quick start (any new device)

```bash
git clone https://github.com/techminion/home-lab.git
cd home-lab
cp config.env.example config.env    # edit: git name/email, tailscale flags
./bootstrap.sh
exec zsh
```

Run only some modules:

```bash
./bootstrap.sh podman tailscale
```

## What each module does

| Module      | Action                                                                                                         |
| ----------- | -------------------------------------------------------------------------------------------------------------- |
| `packages`  | Installs zsh + base tools (git, tmux, fzf, ripgrep, bat, …). Installs Homebrew on macOS, enables EPEL on RHEL. |
| `zsh`       | oh-my-zsh + plugins, symlinks `dotfiles/zshrc` & `tmux.conf`, sets zsh as default shell.                       |
| `git`       | Symlinks base gitconfig, applies name/email/signing from `config.env`.                                         |
| `podman`    | Podman rootless + podman-compose; enables the user socket and lingering.                                       |
| `tailscale` | Installs Tailscale and runs `tailscale up` (interactive browser login).                                        |

## Configuration

All per-device settings live in `config.env` (git-ignored). Start from
`config.env.example`. Nothing secret is committed.

- `MODULES` — which modules run by default.
- `GIT_USER_NAME` / `GIT_USER_EMAIL` / `GIT_SIGNING_KEY` — git identity.
- `TAILSCALE_FLAGS` — extra `tailscale up` flags (e.g. `--ssh --accept-routes`).
- `TAILSCALE_HOSTNAME` — override the device name in your tailnet.

## Adding a device

1. Add a module under `modules/<name>.sh` defining `module_<name>()` if you need
   new functionality — it's auto-discovered by name.
2. On the new machine, clone, copy `config.env`, run `./bootstrap.sh`.

Per-device shell tweaks that shouldn't be shared go in `~/.zshrc.local`
(sourced automatically, not tracked).

## Layout

```
bootstrap.sh          entrypoint / module runner
lib/common.sh         OS detection + helpers (pkg_install, link_file, …)
modules/*.sh          one file per concern
dotfiles/*            tracked configs, symlinked into $HOME
config.env.example    template (copy to config.env)
```

## Notes

- The **agnoster** theme needs a Nerd/Powerline font in your _terminal_
  (usually your Mac). `brew install --cask font-meslo-lg-nerd-font`, then set it.
- Tailscale login is interactive by design — no auth keys stored on disk.
- macOS Podman runs containers in a managed Linux VM (`podman machine`),
  started automatically by the module.

```

```
