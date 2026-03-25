-- core/state.lua

-- Глобальная таблица аддона
-- Используем один namespace, чтобы не засорять global scope
HardcoreChallenges = {}

-- Runtime состояние (живёт только пока запущена игра)
HardcoreChallenges.state = {
    initialized = false,   -- был ли уже выполнен init
    playerLoaded = false,  -- зашел ли игрок в мир
}

-- Здесь можно будет позже добавить:
-- activeChallengesCache
-- eventSubscribers