---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Info = require('Module:Info')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	if not Info.config.squad.allowManual then
		error('This wiki do not use manual squad tables')
	end

	return SquadUtils.defaultRunManual(frame, Squad, SquadUtils.defaultRow(SquadRow)
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	return SquadUtils.defaultRunAuto(playerList, squadType, Squad, SquadUtils.defaultRow(SquadRow))
end

return CustomSquad
