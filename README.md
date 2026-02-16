# ☁️ RClone Auto

> **The "Set and Forget" Rclone Manager for Linux.**
> Manage Cloud Mounts & Syncs with a professional Terminal UI (TUI) or CLI commands.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

**RClone Auto** is a standalone Bash script that automates the management of **Rclone** remotes. It handles dependencies, creates persistent `systemd` services, enforces naming conventions, and offers a hybrid interface (Interactive Menu + CLI Arguments).

---

## ✨ Key Features

* **🖥️ Native TUI:** Uses **Whiptail** for a clean, fast, and keyboard-friendly interface (Debian installer style).
* **🚀 Smart Auto-Launch:** If you click the shortcut in your App Menu, it automatically detects it's not in a terminal and launches your preferred terminal emulator (Konsole, Gnome Terminal, Xterm, etc.) to run the script.
* **⚡ Dual Modes:**
    * **Mount Mode:** Streams files as a Virtual Drive (saves disk space).
    * **Sync Mode:** Creates a real offline copy that syncs bidirectionally every **15 minutes** (via systemd timers).
* **🏷️ Standardization:** Automatically enforces organized naming conventions (e.g., `drive-personal`, `onedrive-work`).
* **🤖 CLI Automation:** Supports flags like `--mount`, `--stop`, and `--sync` for scripting and power users.
* **📦 Self-Updating:** The script automatically installs itself to `~/.local/bin/` and updates its own desktop shortcuts.

---

## 📦 Installation

You don't need to install Rclone beforehand. The script handles everything.

```bash
# 1. Download the script
wget [https://raw.githubusercontent.com/YOUR_USERNAME/REPO_NAME/main/rclone-auto.sh](https://raw.githubusercontent.com/YOUR_USERNAME/REPO_NAME/main/rclone-auto.sh)

# 2. Make it executable
chmod +x rclone-auto.sh

# 3. Run it
./rclone-auto.sh

> **On the first run:** It will check for dependencies (`rclone`, `fuse3`, `whiptail`) and offer to install them automatically. It will also create a shortcut in your Application Menu.

---

## 🎮 Usage

### Interactive Mode (Menu)

Just run the command (or click the **RClone Auto** icon in your menu):

```bash
rclone-auto

```

This opens the **Main Dashboard** where you can:

1. **New Connection:** Wizard to authenticate (Google, OneDrive, Dropbox, etc.) and choose between Mount or Sync.
2. **Manage:** View active services, start stopped remotes, or stop/remove active ones.
3. **Renaming:** Standardize old connections to the new format.

### CLI Mode (Power Users)

You can control your clouds directly from the terminal without opening the menu:

| Flag | Description | Example |
| --- | --- | --- |
| `--list` | List active services (systemd) and available remotes. | `rclone-auto --list` |
| `--mount <name>` | Mounts an existing remote to `~/Nuvem/<name>`. | `rclone-auto --mount drive-work` |
| `--sync <name>` | Schedules a bidirectional sync (15m timer). | `rclone-auto --sync onedrive-personal` |
| `--stop <name>` | Stops and disables the mount/sync service. | `rclone-auto --stop drive-work` |
| `--install` | Forces a reinstall of the script and shortcuts. | `rclone-auto --install` |
| `--help` | Shows the help message. | `rclone-auto --help` |

---

## 🛠️ How it Works

1. **Persistence:** It creates user-level systemd units (`rclone-mount-NAME.service` or `rclone-sync-NAME.timer`).
2. **Folder Structure:** All clouds are mounted/synced to `~/Nuvem/` (or `~/Cloud`).
3. **Sync Logic:** The **Sync Mode** uses `rclone bisync` (bidirectional sync) with safety checks, running 5 minutes after boot and every 15 minutes thereafter.
4. **Icons:** Sets standard Linux icons (`folder-remote`) for the parent directory to ensure visual consistency in file managers (Dolphin, Nautilus, Nemo).

---

## 📋 Requirements

* **Linux:** Tested on Ubuntu, Kubuntu, Debian, Fedora, Arch.
* **Dependencies:** `curl`, `unzip`, `fuse3`, `whiptail`.
* **Rclone:** The script can download the official binary if missing.

---

## 🤝 Contributing

Pull requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add NewFeature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License.
