-- db.lua
local addon = HardcoreChallenges

--[[ 
    Функция доступа к базе данных персонажа.
    Используем для чтения и записи данных текущего персонажа.
    Пример использования:
        local db = addon:GetCharDB()
        print(db.characterStarted)
]]
function addon:GetCharDB()
    return self.CharDB
end