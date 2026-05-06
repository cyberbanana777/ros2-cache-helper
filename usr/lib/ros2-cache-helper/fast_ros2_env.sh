#!/usr/bin/env bash
# ============================================================
# fast_ros2_env.sh – быстрое кэширование окружения ROS 2
# Использование:
#   source fast_ros2_env.sh <setup1.bash> [setup2.bash ...]
#   source fast_ros2_env.sh --clean
#   source fast_ros2_env.sh --help
#   source fast_ros2_env.sh --version
# ============================================================


# ----------------------------------------------------------------------
# Конфигурация
_ROS2_CACHE_DIR="$HOME/.cache/ros2_multi_cache"
_VERSION="1.0.1"
_COPYRIGHT="Copyright (c) 2026 Alice Zenina and Alexander Grachev RTU MIREA (Russia). License: MIT"

# ----------------------------------------------------------------------
# Функции вывода справки и версии
show_help() {
    cat << 'EOF'
Usage: source fast_ros2_env.sh [OPTION]... [SETUP_FILE]...

Fast environment caching for ROS 2 workspaces.
Caches the combined environment of multiple ROS 2 setup files
to speed up shell startup on slow filesystems (e.g., SD card).

Options:
  -h, --help     display this help and exit
  -v, --version  output version information and exit
      --clean    remove all cached environments and exit

Arguments:
  SETUP_FILE     one or more ROS 2 setup.bash or local_setup.bash files
                 (order matters: they will be sourced in the given order)

Examples:
  source fast-ros2-env /opt/ros/humble/setup.bash ~/ws/install/setup.bash
  source fast-ros2-env --clean

Report bugs to: <sashagrachev2005@gmail.com>
EOF
}

show_version() {
    cat << EOF
fast_ros2_env.sh version $_VERSION
$_COPYRIGHT
This is free software; see the source for copying conditions.
EOF
}

# ----------------------------------------------------------------------
# Обработка --help и --version ДО любой другой логики
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            return 0 2>/dev/null || exit 0
            ;;
        -v|--version)
            show_version
            return 0 2>/dev/null || exit 0
            ;;
    esac
done

# ----------------------------------------------------------------------
# Очистка кэша (если передан --clean)
clean_ros2_cache() {
    rm -rf "$_ROS2_CACHE_DIR"
    echo "ROS 2 cache cleared. Next shell will rebuild."
}

if [[ "$1" == "--clean" ]]; then
    clean_ros2_cache
    return 0 2>/dev/null || exit 0
fi

# ----------------------------------------------------------------------
# Проверяем, что передан хотя бы один setup-файл
if [[ $# -eq 0 ]]; then
    echo "ERROR: No setup files provided." >&2
    echo "Usage: source $0 <setup1.bash> [setup2.bash ...]" >&2
    echo "Try '$0 --help' for more information." >&2
    return 1 2>/dev/null || exit 1
fi

# ----------------------------------------------------------------------
# Основная логика (кэширование)
mkdir -p "$_ROS2_CACHE_DIR"
_ros2_setup_files=("$@")

_ros2_build_cache() {
    local cache_file="$1"
    echo "Building ROS 2 environment cache from ${#_ros2_setup_files[@]} files..." >&2
    local env_before=$(env | sort)
    local env_after=$(
        for f in "${_ros2_setup_files[@]}"; do
            if [[ -f "$f" ]]; then
                source "$f"
            fi
        done
        env | sort
    )
    comm -13 <(echo "$env_before") <(echo "$env_after") > "$cache_file.tmp"
    {
        echo "#!/usr/bin/env bash"
        echo "# Cache for: ${_ros2_setup_files[*]}"
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                key="${line%%=*}"
                value="${line#*=}"
                printf 'export %s=%q\n' "$key" "$value"
            fi
        done < "$cache_file.tmp"
    } > "$cache_file"
    rm -f "$cache_file.tmp"
    chmod +x "$cache_file"
    echo "Cache saved to $cache_file" >&2
}

# Вычисляем ключ кэша
_key=""
for f in "${_ros2_setup_files[@]}"; do
    if [[ -f "$f" ]]; then
        _key="${_key}${f}:$(stat -c %Y "$f")"
    else
        echo "WARNING: File '$f' does not exist, skipping from cache key" >&2
    fi
done
_hash=$(echo -n "$_key" | md5sum | cut -d' ' -f1)
_cache_file="$_ROS2_CACHE_DIR/$_hash.sh"

_needs_build=0
if [[ ! -f "$_cache_file" ]]; then
    _needs_build=1
else
    for f in "${_ros2_setup_files[@]}"; do
        if [[ -f "$f" ]] && [[ "$f" -nt "$_cache_file" ]]; then
            _needs_build=1
            break
        fi
    done
fi

if [[ $_needs_build -eq 1 ]]; then
    _ros2_build_cache "$_cache_file"
fi


# Загружаем кэш
source "$_cache_file"

# Уборка
unset _ROS2_CACHE_DIR _VERSION _COPYRIGHT _ros2_setup_files _key _hash _cache_file _needs_build
# ============================================================