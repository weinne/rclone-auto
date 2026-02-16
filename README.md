```markdown
# ☁️ RClone Auto

> **The "Set and Forget" Rclone Manager for Linux.**
> Mount Google Drive, OneDrive, S3, and others as local folders with a native GUI or Terminal UI.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

**RClone Auto** is a standalone Bash script that automates the mounting of cloud storage using **Rclone**. It handles dependencies, creates persistent systemd services, and offers a hybrid interface that adapts to your environment (Desktop vs. Server).

---

## ✨ Key Features

* **🖥️ Hybrid Interface:** Automatically detects your environment.
    * **GUI Mode:** Uses **Zenity** for a native desktop experience (GNOME, KDE, XFCE).
    * **TUI Mode:** Uses **Whiptail** for SSH/Server sessions.
* **🔒 Zero Sudo Required:** Runs entirely in user-space. No root privileges needed.
* **🚀 Persistence:** Creates `systemd --user` units. Your cloud drives mount automatically when you log in or boot up.
* **⚡ Performance Tuned:** Pre-configured with optimal VFS cache flags (`--vfs-cache-mode full`) for smooth file editing and streaming.
* **📦 Auto-Install:** Automatically fetches the official Rclone binary and sets up a Desktop Shortcut with an icon on the first run.

---

## 📦 Installation

You don't need to install anything beforehand. Just download the script and run it.

```bash
# 1. Download the script
wget [https://raw.githubusercontent.com/YOUR_USERNAME/REPO_NAME/main/rclone-auto.sh](https://raw.githubusercontent.com/YOUR_USERNAME/REPO_NAME/main/rclone-auto.sh)

# 2. Make it executable
chmod +x rclone-auto.sh

# 3. Run it
./rclone-auto.sh

```

> **Note:** On the first run, it will verify dependencies (`rclone`, `fuse3`) and create a shortcut in your Application Menu.

---

## 🎮 Usage

You can launch **RClone Auto** from your Application Menu (search for "RClone Auto") or run it via terminal with optional flags:

### Automatic Mode (Default)

Detects if a graphical display is available. If yes, opens GUI; otherwise, opens TUI.

```bash
./rclone-auto.sh

```

### Force GUI Mode

Forces the Zenity interface (requires a desktop environment).

```bash
./rclone-auto.sh --gui

```

### Force Terminal Mode

Forces the Whiptail interface (useful for remote management via SSH).

```bash
./rclone-auto.sh --tui

```

---

## 🛠️ How it Works

1. **Mounting:** It creates a mount point in `~/Nuvem/REMOTE_NAME` (or any folder you choose).
2. **Systemd Service:** It generates a user service file at `~/.config/systemd/user/rclone-mount-NAME.service`.
3. **Boot:** It enables the service using `systemctl --user enable`. This ensures the drive is mounted every time the system starts (user login).
4. **Icons:** It fetches the official Rclone logo and installs it to `~/.local/share/icons/` to ensure the window and shortcut look professional.

---

## 📋 Requirements

The script checks for these and attempts to solve missing dependencies:

* **Rclone:** If missing, the script offers to download the official static binary to `~/.local/bin/`.
* **FUSE 3:** Required for mounting (`sudo apt install fuse3` on Ubuntu/Debian).
* **Zenity:** Required for GUI mode (pre-installed on most distros).
* **Whiptail:** Required for TUI mode (pre-installed on most distros).

---

## 🤝 Contributing

Pull requests are welcome! Feel free to open an issue if you find a bug or have a feature request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

```
