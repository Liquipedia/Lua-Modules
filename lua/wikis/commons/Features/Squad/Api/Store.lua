---
-- @Liquipedia
-- page=Module:Features/Squad/Api/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local SquadStore = {}

---@param squadPerson ModelRow
function SquadStore.storeSquadPerson(squadPerson)
	squadPerson:save()
end

return SquadStore
