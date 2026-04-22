---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

local Squad = Lua.import('Module:Squad/Controller')

local CustomSquad = {}

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	return Squad.run(frame)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return Squad.runAuto(players, squadStatus, squadType, customTitle)
end

return CustomSquad
