-- core/events.lua

-- Создаем основной frame для подписки на события
local eventFrame = CreateFrame("Frame")

-- Таблица обработчиков (event -> function)
HardcoreChallenges.events = {}

-- Универсальная функция регистрации событий
function HardcoreChallenges:RegisterEvent(event, handler)
    -- Регистрируем событие в WoW
    eventFrame:RegisterEvent(event)

    -- Сохраняем обработчик
    HardcoreChallenges.events[event] = handler
end

-- Главный dispatcher событий
eventFrame:SetScript("OnEvent", function(_, event, ...)
    -- Проверяем есть ли обработчик
    local handler = HardcoreChallenges.events[event]

    if handler then
        handler(...)
    end
end)

-- 💡 Позже ты можешь расширить это:
-- - несколько обработчиков на событие
-- - middleware система