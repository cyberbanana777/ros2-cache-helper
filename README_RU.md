
# ROS2 Cache Helper

**Быстрое кэширование окружения для ROS 2 workspace**

[![Лицензия: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian Package](https://img.shields.io/badge/deb-package-blue)](https://github.com/cyberbanana777/ros2-cache-helper/releases)

Этот инструмент значительно ускоряет активацию сложных окружений ROS 2 за счёт кэширования объединённого результата выполнения нескольких файлов `setup.bash` / `local_setup.bash`. Особенно полезен на устройствах с ограниченными ресурсами, таких как **NVIDIA Jetson Nano**, где чтение множества мелких файлов с SD‑карты происходит медленно.

Обычно выполнение `source` для большого ROS 2 workspace (или нескольких overlays) занимает **5–10 секунд**. С этим помощником последующие запуски терминала занимают **< 0.5 секунды** – без потери переменных окружения.

---

## ✨ Возможности

- Кэширует **объединённое окружение** нескольких ROS 2 workspace (база + overlays).
- Автоматически перестраивает кэш при изменении любого файла `setup.bash`.
- Работает с **любым** дистрибутивом ROS 2 (Galactic, Humble, Iron, Rolling…).
- Поддерживает `--clean` для очистки кэша.
- Предоставляет опции `--help` и `--version`.
- Устанавливается как системный пакет (`.deb`), готов для Ubuntu 20.04/22.04 (arm64, amd64).

---

## 📦 Установка

### Из готового `.deb` пакета (рекомендуется)

1. Скачайте последний `.deb` файл на странице [Releases](https://github.com/cyberbanana777/ros2-cache-helper/releases).

2. Установите его:
    ```bash
    sudo apt install ./ros2-cache-helper-*.deb
    ```
    или
    ```bash
    sudo dpkg -i ros2-cache-helper-*.deb
    sudo apt-get install -f   # установить зависимости, если потребуются
    ```
3. Добавьте ваши ROS 2 workspace в `~/.bashrc` (см. раздел «Использование»).

### Сборка из исходников (вручную)
Если вы предпочитаете установку без `.deb` пакета:

```bash
git clone https://github.com/cyberbanana777/ros2-cache-helper.git
cd ros2-cache-helper
sudo cp usr/lib/ros2-cache-helper/fast_ros2_env.sh /usr/lib/ros2-cache-helper/
sudo cp usr/lib/ros2-cache-helper/fast-ros2-env /usr/bin/
sudo chmod 755 /usr/bin/fast-ros2-env /usr/lib/ros2-cache-helper/fast_ros2_env.sh
```

## 🚀 Использование
1. Отредактируйте ваш `~/.bashrc` и добавьте строку, которая выполняет source помощника со всеми вашими файлами ROS 2 setup, в том порядке, в котором они должны быть загружены:

```bash
source /usr/bin/fast-ros2-env \
    /opt/ros/humble/setup.bash \
    ~/ros2_ws/install/setup.bash \
    ~/nav2_ws/install/setup.bash
```
или
```bash
source fast-ros2-env \
    /opt/ros/humble/setup.bash \
    ~/ros2_ws/install/setup.bash \
    ~/nav2_ws/install/setup.bash
```

> **Важно**: Используйте **абсолютные пути** к каждому `setup.bash` (или `local_setup.bash`).
> Порядок важен: сначала базовый дистрибутив, затем overlays.

2. **Закройте и откройте заново терминал** (или выполните `source ~/.bashrc`).
Первый запуск создаст кэш – это может занять несколько секунд.
Все последующие терминалы будут запускаться мгновенно.

3. Проверьте, что ваше окружение загружено корректно:
```bash
env | grep ROS
```

## 🧹 Управление кэшем
- **Очистить кэш** (принудительная перестройка при следующем запуске терминала):
```bash
source /usr/bin/fast-ros2-env --clean
```
- **Показать справку**:
```bash
source /usr/bin/fast-ros2-env --help
```
- **Проверить версию**:
```bash
source /usr/bin/fast-ros2-env --version
```

## 📘 Опции и аргументы
```text
Использование: source fast-ros2-env [ОПЦИЯ]... [ФАЙЛ_SETUP]...

Опции:
  -h, --help     показать эту справку и выйти
  -v, --version  вывести информацию о версии и выйти
      --clean    удалить все кэшированные окружения и выйти

Аргументы:
  ФАЙЛ_SETUP     один или несколько файлов setup.bash или local_setup.bash
                 (порядок важен – они будут загружены в указанном порядке)
```

## 💡 Примеры
### Простое использование с одним workspace
```bash
source /usr/bin/fast-ros2-env /opt/ros/humble/setup.bash
```
### Сложная цепочка overlays
```bash
source /usr/bin/fast-ros2-env \
    /opt/ros/galactic/setup.bash \
    ~/sllidar_ws/install/local_setup.bash \
    ~/nav2_ws/install/local_setup.bash \
    ~/jetbot_ws/install/local_setup.bash
```
### После изменения содержимого workspace (например, пересборки)
Если вы пересобрали workspace, временная метка соответствующего `setup.bash` изменится. При следующем запуске терминала кэш будет автоматически перестроен. Также можно очистить кэш вручную:

```bash
source /usr/bin/fast-ros2-env --clean
```

## 📁 Как это работает
1. Скрипт запоминает текущее окружение (`env | sort`).

2. Затем он последовательно выполняет `source` каждого переданного `setup.bash` внутри под‑оболочки.

3. После всех источников он снова снимает окружение и вычисляет **разницу** с помощью `comm -13`.

4. Разница (новые или изменённые переменные) сохраняется в виде bash-скрипта, содержащего только команды `export VAR=value`.

5. При следующем вызове помощника он просто выполняет этот предварительно сгенерированный скрипт – никаких отдельных скриптов для каждого пакета, никаких проверок дубликатов, никакой медленной работы ввода‑вывода.

Все файлы кэша хранятся в `~/.cache/ros2_multi_cache/`. Ключ кэша зависит от абсолютных путей и времени их изменения, поэтому изменения обнаруживаются автоматически.

## 🤝 Участие в разработке
Приветствуются вопросы и pull requests!
Сообщайте об ошибках или предлагайте улучшения через [GitHub Issues](https://github.com/cyberbanana777/ros2-cache-helper/issues).

## 📄 Лицензия
Этот проект распространяется под лицензией MIT – подробности в файле [LICENSE](LICENSE).

## 🙏 Благодарности
Создано под впечатлением от необходимости выживать на медленных SD‑картах Jetson Nano. Спасибо сообществу ROS 2 за гибкую архитектуру workspace (даже если она медленная).
