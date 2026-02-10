## Mortis HACK v10.1

Многофункциональный скрипт для Roblox с удобной модульной структурой:

- **Aimbot**: плавное/агрессивное наведение, FOV‑круг, пресеты.
- **ESP / WH**: подсветка игроков по командам (headcloth / band / neutral).
- **Combat**: Magic Bullet, Anti‑Recoil, No Hand Shake.
- **Movement**: Fly, Noclip, Speed, Jump Power, Infinite Jump, Spin.
- **Player / Camera**: GodMode, Invis, телепорты, FreeCam.
- **Visuals**: Fullbright, Always Day, No Fog.

Все функции разделены по модулям, а единая точка входа — `main.lua`.

---

## Структура проекта

- **`main.lua`**  
  Точка входа. Подгружает остальные модули по HTTP (`game:HttpGet`) и вызывает `Mortis.init()`.

- **`core.lua`**  
  - Инициализация сервисов (`Players`, `Workspace`, `RunService`, `UserInputService`, `Lighting` и т.п.).  
  - Глобальный контейнер `getgenv().Mortis`.  
  - Основная таблица настроек `Mortis.Settings`.  
  - Поиск своего персонажа: `findMyModel`, `getHumanoid`, `getHRP`.  
  - Поиск головы/лучшей цели: `findCorrectHead`, `findBestTargetPart`.  
  - Живость моделей и «команды»: `isModelAlive`, `getTeamType`.  
  - Anti‑AFK.

- **`lighting.lua`**  
  - Сохранение оригинальных настроек света.  
  - `applyFullbright`, `applyAlwaysDay`, `applyRemoveFog`, `maintainLighting`.  
  - Guard’ы на свойства `Lighting` (`GetPropertyChangedSignal`), чтобы карта не затемнялась.

- **`movement.lua`**  
  - Fly: `startFly`, `stopFly`, `updateFly`.  
  - Noclip, Speed Hack, Jump Power, GodMode.  
  - Invis, BigHead (Hitbox Expander).  
  - Телепорт к курсору / игроку.  
  - FreeCam с настраиваемой скоростью.

- **`esp.lua`**  
  - Полный ESP / Wallhack.  
  - Создание/обновление `Highlight` для моделей.  
  - Отслеживание `Characters` и автообновление цветов/команд.  
  - `updateESP()` возвращает количество найденных игроков.

- **`aim.lua`**  
  - Обработка клавиши аима: `isAimKeyPressed`.  
  - FOV‑круг через `Drawing` API: `createFOVCircle`.  
  - Логика выбора цели: `getBestTarget`.  
  - Наведение мыши: `aimAt`.  
  - Magic Bullet: `getMagicBulletTarget`.  
  - Anti‑Recoil: `applyAntiRecoil`.  
  - No Hand Shake: `applyNoHandShake`, `setupNoHandShakeHook`.

- **`ui.lua`**  
  - Fluent UI (tabs, toggles, sliders, buttons).  
  - Вкладки: ESP, Aimbot, (Combat, Movement, Player, Visuals, Settings).  
  - Все элементы UI управляют `Mortis.Settings` и вызывают функции из других модулей.

- **`runtime.lua`**  
  - Хук `__namecall` для Magic Bullet.  
  - Обработка ввода (Infinite Jump, ClickTP).  
  - Циклы `RunService.Stepped/RenderStepped/Heartbeat`.  
  - Основная функция `Mortis.init()`: инициализация света, UI, ESP, FOV‑круга и уведомлений.

---

## Как использовать (Xeno / любой Lua‑экзекьютор)

### 1. Залей файлы на GitHub

1. Создай репозиторий, например `MortisHack`.
2. Добавь в него все файлы из папки проекта:
   - `main.lua`
   - `core.lua`
   - `lighting.lua`
   - `movement.lua`
   - `esp.lua`
   - `aim.lua`
   - `ui.lua`
   - `runtime.lua`

3. Получи **raw‑ссылку** на `main.lua`, например:  
   `https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua`

### 2. Настрой `BASE_URL` в `main.lua`

В начале `main.lua` есть константа:

```lua
local BASE_URL = "https://example.com/mortis/"
```

- Замени её на путь к папке, где лежат остальные модули.  
- Пример, если все файлы лежат в корне репо:

```lua
local BASE_URL = "https://raw.githubusercontent.com/<USER>/<REPO>/main/"
```

Массив `MODULES` уже настроен под текущую структуру:

```lua
local MODULES = {
    "core",
    "lighting",
    "movement",
    "esp",
    "aim",
    "ui",
    "runtime",
}
```

Ничего менять не нужно, если имена файлов совпадают.

### 3. Запуск через Xeno

1. Вставь в Xeno (или другой экзекьютор) такую строку, подставив **свою** raw‑ссылку:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua"))()
```

2. `main.lua`:
   - создаст глобальный `getgenv().Mortis`,
   - скачает все модули из `BASE_URL`,
   - выполнит их и сохранит в `Mortis.Modules[...]`,
   - вызовет `Mortis.init()` из `runtime.lua`.

3. В игре откроется Fluent‑меню с вкладками:
   - **ESP**
   - **Aimbot**
   - (остальные – Combat, Movement, Player, Visuals, Settings, если полностью перенесён UI).

---

## Частые вопросы

- **Можно ли использовать только часть функций (например, только аим + ESP)?**  
  Да: убери лишние имена из `MODULES` в `main.lua` и/или не добавляй соответствующие вкладки в `ui.lua`.

- **Где менять настройки по умолчанию?**  
  В файле `core.lua` в таблице `Settings` (ESP, Aimbot, Fly, Speed и др.).

- **Как изменить клавишу активации аима?**  
  В игре — во вкладке **Aimbot** (dropdown AimKey), либо в `Settings.Aimbot_KeyMode` в `core.lua`.

