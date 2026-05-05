# ROS2 Cache Helper

This tool caches the combined environment variables of multiple ROS2 workspaces to speed up `source` on slow filesystems (e.g., SD card on Jetson).

## Usage

1. Add to your `~/.bashrc`:

```bash
source /usr/local/bin/fast-ros2-env \
    "$HOME/ros2_galactic/install/local_setup.bash" \
    "/opt/ros/galactic/setup.bash" \
    "$HOME/nav2_ws/install/local_setup.bash"
```

2. First run will build cache (takes ~5 sec). Subsequent runs are instant.

3. To clear cache: source /usr/local/bin/fast-ros2-env --clean

## Requirements

- ROS2 workspace must already be built.
- The script must be source-ed, not executed directly.