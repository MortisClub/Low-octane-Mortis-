## Mortis HACK v10.1

Многофункциональный модульный скрипт для Roblox с удобным UI и аккуратной архитектурой.

- **Aimbot**: плавное/агрессивное наведение, FOV‑круг, Magic Bullet, Anti‑Recoil, No Hand Shake  
- **ESP / WH**: подсветка игроков по командам (headcloth / band / neutral)  
- **Movement**: Fly, Noclip, Speed, Jump Power, Infinite Jump, Spin  
- **Player / Camera**: GodMode, Invis, телепорты, FreeCam  
- **Visuals**: Fullbright, Always Day, No Fog  

Все функции разнесены по модулям, а единая точка входа — `main.lua`  
([посмотреть на GitHub](https://github.com/MortisClub/Low-octane-Mortis-/blob/main/main.lua)).

---

## Быстрый старт

1. **Залей файлы в свой репозиторий GitHub**
   - `main.lua`
   - `core.lua`
   - `lighting.lua`
   - `movement.lua`
   - `esp.lua`
   - `aim.lua`
   - `ui.lua`
   - `runtime.lua`

2. **получи raw‑ссылку** на `main.lua`, например:  
   `https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua`

3. **запусти в Xeno / SynX / другом Lua‑экзекьюторе**:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua"))()
```

После этого `main.lua` автоматически:
- создаст глобальный контейнер `getgenv().Mortis`,
- скачает все модули из `BASE_URL`,
- выполнит их и сохранит в `Mortis.Modules[...]`,
- вызовет `Mortis.init()` (реализована в `runtime.lua`).

---

## Настройка `BASE_URL` в `main.lua`

В начале `main.lua` есть константа:

```lua
local BASE_URL = "https://example.com/mortis/"
```

- Замени её на путь к папке, где лежат **все остальные .lua файлы**.  
- Если файлы лежат в корне репозитория, подойдёт:

```lua
local BASE_URL = "https://raw.githubusercontent.com/<USER>/<REPO>/main/"
```

Список модулей уже заранее настроен под текущую структуру:

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

Если имена файлов не менялись — **ничего трогать не нужно**.

---

## Структура проекта

- **`main.lua`**  
  Точка входа. Подгружает остальные модули по HTTP (`game:HttpGet`), выполняет их и в конце вызывает `Mortis.init()`.

- **`core.lua`**  
  - Инициализация сервисов (`Players`, `Workspace`, `RunService`, `UserInputService`, `Lighting` и т.д.)  
  - Глобальный контейнер `getgenv().Mortis`  
  - Таблица настроек `Mortis.Settings`  
  - Поиск персонажа и частей: `findMyModel`, `getHumanoid`, `getHRP`, `findCorrectHead`  
  - Логика команд/тимов: `getTeamType`, `isModelAlive`  
  - Anti‑AFK

- **`lighting.lua`**  
  - Сохранение оригинальных настроек света  
  - `applyFullbright`, `applyAlwaysDay`, `applyRemoveFog`, `maintainLighting`  
  - Защита от попыток карты «выключить» свет (`GetPropertyChangedSignal` на `Lighting`)

- **`movement.lua`**  
  - Fly (`startFly`, `stopFly`, `updateFly`)  
  - Noclip, Speed Hack, Jump Power, GodMode  
  - Invis, BigHead (Hitbox Expander)  
  - Телепорт к курсору / игроку  
  - FreeCam с настраиваемой скоростью

- **`esp.lua`**  
  - Полноценный ESP / Wallhack  
  - Создание и обновление `Highlight` для моделей  
  - Отслеживание `Characters` и автообновление цветов/команд  
  - `updateESP()` — возвращает количество подсвеченных игроков

- **`aim.lua`**  
  - Обработка клавиши аима: `isAimKeyPressed`  
  - FOV‑круг через `Drawing` API: `createFOVCircle`  
  - Выбор цели: `getBestTarget`, `getMagicBulletTarget`  
  - Наведение: `aimAt`  
  - Anti‑Recoil, No Hand Shake (`applyAntiRecoil`, `applyNoHandShake`, `setupNoHandShakeHook`)

- **`ui.lua`**  
  - Fluent‑стиль интерфейса (tabs, toggles, sliders, buttons)  
  - Вкладки: ESP, Aimbot, Combat, Movement, Player, Visuals, Settings  
  - Все элементы UI крутят `Mortis.Settings` и вызывают функции из других модулей

- **`runtime.lua`**  
  - Хук `__namecall` для Magic Bullet  
  - Обработка ввода (Infinite Jump, ClickTP и др.)  
  - Циклы `RunService.Stepped / RenderStepped / Heartbeat`  
  - Основная функция `Mortis.init()`: запуск света, ESP, FOV‑круга, UI и прочих подсистем

---

## Использование (Xeno / любой Lua‑экзекьютор)

1. Вставь строку запуска с **своей** raw‑ссылкой:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua"))()
```

2. Дождись загрузки модулей и появления Fluent‑меню.
3. Настрой нужные функции во вкладках:
   - **ESP** — подсветка игроков  
   - **Aimbot** — ключ активации, FOV, режимы наведения  
   - **Combat / Movement / Player / Visuals / Settings** — остальной функционал

---

## FAQ

- **Можно ли вырезать лишние функции и оставить только ESP + Aimbot?**  
  Да. Убери ненужные имена из массива `MODULES` в `main.lua` и/или не добавляй соответствующие вкладки в `ui.lua`.

- **Где менять настройки по умолчанию (FOV, скорость Fly, клавиши и т.п.)?**  
  В `core.lua` в таблице `Mortis.Settings` (секции ESP, Aimbot, Fly, Speed и др.).

- **Как поменять клавишу активации аима?**  
  - В игре — во вкладке **Aimbot** (параметр AimKey / режим KeyMode).  
  - Либо вручную — в `Settings.Aimbot_KeyMode` в `core.lua`.

- **Почему ничего не происходит после запуска?**  
  - Проверь, что `BASE_URL` указывает на рабочую папку с модулями.  
  - Убедись, что файлы названы `core.lua`, `lighting.lua`, `movement.lua`, `esp.lua`, `aim.lua`, `ui.lua`, `runtime.lua`.  
  - Посмотри в консоль Roblox Studio / экзекьютора — `main.lua` пишет предупреждения, если модуль не скачался или не скомпилировался.

