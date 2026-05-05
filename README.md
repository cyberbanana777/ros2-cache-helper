# ROS2 Cache Helper

**Fast environment caching for ROS 2 workspaces**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian Package](https://img.shields.io/badge/deb-package-blue)](https://github.com/cyberbanana777/ros2-cache-helper/releases)

This tool dramatically speeds up the activation of complex ROS 2 environments by caching the combined result of sourcing multiple `setup.bash` / `local_setup.bash` files. It is especially useful on resource‑constrained devices like **NVIDIA Jetson Nano** where reading many small files from an SD card is slow.

Normally, sourcing a large ROS 2 workspace (or several overlays) takes **5–10 seconds**. With this helper, subsequent terminal starts take **< 0.5 second** – without losing any environment variables.

---

## ✨ Features

- Caches the **merged environment** of multiple ROS 2 workspaces (base + overlays).
- Automatically rebuilds cache when any `setup.bash` file changes.
- Works with **any** ROS 2 distribution (Galactic, Humble, Iron, Rolling…).
- Supports `--clean` to wipe the cache.
- Provides `--help` and `--version` options.
- Installs as a system package (`.deb`), ready for Ubuntu 20.04/22.04 (arm64, amd64).

---

## 📦 Installation

### From prebuilt `.deb` package (recommended)

1. Download the latest `.deb` file from the [Releases](https://github.com/cyberbanana777/ros2-cache-helper/releases) page.

2. Install it:
    ```bash
    sudo apt install ./ros2-cache-helper-*.deb
    ```

    or 

    ```bash
    sudo dpkg -i ros2-cache-helper-*.deb
    sudo apt-get install -f   # install dependencies if any
    ```
3. Add your ROS 2 workspaces to `~/.bashrc` (see Usage).

### Building from source (manual)
If you prefer to install manually without the .deb package:

```bash
git clone https://github.com/cyberbanana777/ros2-cache-helper.git
cd ros2-cache-helper
sudo cp usr/lib/ros2-cache-helper/fast_ros2_env.sh /usr/lib/ros2-cache-helper/
sudo cp usr/lib/ros2-cache-helper/fast-ros2-env /usr/bin/
sudo chmod 755 /usr/bin/fast-ros2-env /usr/lib/ros2-cache-helper/fast_ros2_env.sh
```

## 🚀 Usage
1. Edit your `~/.bashrc` and add a line that sources the helper with all your ROS 2 setup files, in the order they should be sourced:

```bash
source /usr/bin/fast-ros2-env \
    /opt/ros/humble/setup.bash \
    ~/ros2_ws/install/setup.bash \
    ~/nav2_ws/install/setup.bash
```
or
```bash
source fast-ros2-env \
    /opt/ros/humble/setup.bash \
    ~/ros2_ws/install/setup.bash \
    ~/nav2_ws/install/setup.bash
```

> **Important**: Use the **absolute paths** to each `setup.bash` (or `local_setup.bash`).
> The order matters: first the base distribution, then overlays.

2. **Close and reopen your terminal** (or run `source ~/.bashrc`).
The first run will build the cache – it may take a few seconds.
All subsequent terminals will start instantly.

3. Verify that your environment is correctly loaded:

```bash
env | grep ROS
```

## 🧹 Managing the cache
- **Clear the cache** (forces rebuild on next terminal start):

```bash
source /usr/bin/fast-ros2-env --clean
```
- **View help**:

```bash
source /usr/bin/fast-ros2-env --help
```
- **Check version**:

```bash
source /usr/bin/fast-ros2-env --version
```
## 📘 Options & Arguments
```text
Usage: source fast-ros2-env [OPTION]... [SETUP_FILE]...

Options:
  -h, --help     display this help and exit
  -v, --version  output version information and exit
      --clean    remove all cached environments and exit

Arguments:
  SETUP_FILE     one or more ROS 2 setup.bash or local_setup.bash files
                 (order matters – they will be sourced in the given order)
```

## 💡 Examples
### Basic usage with a single workspace
```bash
source /usr/bin/fast-ros2-env /opt/ros/humble/setup.bash
```
### Complex overlay chain
```bash
source /usr/bin/fast-ros2-env \
    /opt/ros/galactic/setup.bash \
    ~/sllidar_ws/install/local_setup.bash \
    ~/nav2_ws/install/local_setup.bash \
    ~/jetbot_ws/install/local_setup.bash
```
### After changing workspace contents (e.g. rebuilding)
If you rebuild a workspace, the corresponding setup.bash timestamp changes. The next terminal start will automatically rebuild the cache. You can also manually clean:

```bash
source /usr/bin/fast-ros2-env --clean
```

## 📁 How it works
1. The script records the current environment (`env | sort`).

2. It then sources each provided `setup.bash` inside a sub‑shell.

3. After all sources, it captures the new environment and computes the **difference** using `comm -13`.

4. The difference (new/changed variables) is saved as a bash script containing only `export VAR=value` commands.

5. The next time you source the helper, it simply executes that pre‑generated script – no per‑package scripts, no duplicate checking, no slow I/O.

All cache files are stored in `~/.cache/ros2_multi_cache/`. The cache key depends on the absolute paths and their modification times, so changes are automatically detected.

## 🤝 Contributing
Issues and pull requests are welcome!
Please report bugs or suggest improvements via [GitHub Issues](https://github.com/cyberbanana777/ros2-cache-helper/issues).

## 📄 License
This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements
Inspired by the need to survive slow SD cards on Jetson Nano. Thanks to the ROS 2 community for the flexible workspace design (even if it’s slow).