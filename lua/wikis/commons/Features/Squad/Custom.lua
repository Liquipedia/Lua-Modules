---
-- @Liquipedia
-- page=Module:Features/Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Features/Squad/Controller')

local CustomSquad = {}

---@param frame Frame
---@return Renderable
function CustomSquad.run(frame)
	return Squad.run(frame)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Renderable
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return Squad.runAuto(players, squadStatus, squadType, customTitle)
end

return CustomSquad
