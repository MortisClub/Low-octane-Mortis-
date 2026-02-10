-- main.lua — загрузчик Mortis Hack
-- Этот файл ты указываешь в Xeno (как ссылку на raw main.lua).
-- Внутри он подтянет остальные .lua файлы из указанной папки.

-- =========================================================
-- НАСТРОЙКА
-- =========================================================

-- Если ты запускаешь чит ЛОКАЛЬНО (через Xeno: loadstring(game:HttpGet(URL_main))()),
-- то этот файл будет лежать на GitHub/хостинге и будет подгружать остальные модули.
--
-- Базовый URL папки, где лежат ВСЕ твои .lua файлы
-- Примеры:
--   "https://raw.githubusercontent.com/USER/REPO/branch/path/to/folder/"
--   "https://example.com/mortis/"
--
-- В ЭТОМ РЕПОЗИТОРИИ уже настроено на GitHub MortisClub:
--   https://raw.githubusercontent.com/MortisClub/Low-octane-Mortis-/main/
-- Если ты форкаешь репо под себя — замени на свой raw‑URL.
local BASE_URL = "https://raw.githubusercontent.com/MortisClub/Low-octane-Mortis-/main/"

-- Список модулей (файлов без .lua), которые нужно подгрузить.
-- Сейчас используется монолитный runtime.lua с оригинальной логикой чита.
local MODULES = {
    "runtime",
}

-- =========================================================
-- ОБЩИЙ ГЛОБАЛ ДЛЯ ВСЕГО ЧИТА
-- =========================================================

getgenv().Mortis = getgenv().Mortis or {}
local Mortis = getgenv().Mortis

Mortis.Modules = Mortis.Modules or {}

-- =========================================================
-- УТИЛИТА ДЛЯ ПОДГРУЗКИ ОДНОГО МОДУЛЯ
-- =========================================================

local function importModule(name)
    local url = BASE_URL .. name .. ".lua"

    local okGet, src = pcall(function()
        return game:HttpGet(url)
    end)

    if not okGet then
        warn(("[Mortis] Не удалось скачать '%s' по URL: %s\nПричина: %s")
            :format(name, url, tostring(src)))
        return
    end

    local chunk, errCompile = loadstring(src, name .. ".lua")
    if not chunk then
        warn(("[Mortis] Ошибка компиляции '%s': %s")
            :format(name, tostring(errCompile)))
        return
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        warn(("[Mortis] Ошибка выполнения '%s': %s")
            :format(name, tostring(result)))
        return
    end

    -- Если модуль что‑то возвращает (таблицу функций) — сохраним.
    Mortis.Modules[name] = result
end

-- =========================================================
-- ЗАГРУЗКА ВСЕХ МОДУЛЕЙ
-- =========================================================

for _, name in ipairs(MODULES) do
    importModule(name)
end

-- =========================================================
-- ФИНАЛЬНАЯ ИНИЦИАЛИЗАЦИЯ
-- =========================================================

-- В одном из модулей (например ui.lua или init.lua)
-- сделай функцию:
--   local Mortis = getgenv().Mortis
--   function Mortis.init()
--       -- создание интерфейса, хуки, циклы RunService и т.д.
--   end
--
-- Тогда main.lua запустит её автоматически.

-- Сейчас вся инициализация (UI, хуки, циклы) происходит внутри runtime.lua,
-- поэтому Mortis.init вызывать не нужно.
print("[Mortis] main.lua: загрузка завершена")

