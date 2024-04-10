---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
function CustomSquad.run(frame)
	error('This wiki doesn\'t support manual Squad Tables')
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	return SquadUtils.defaultRunAuto(playerList, squadType, Squad, SquadUtils.defaultRow(SquadRow))
end

return CustomSquad
