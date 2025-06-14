---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = require('Module:Info')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	if not Info.config.squads.allowManual then
		error('This wiki does not use manual squad tables')
	end

	return SquadUtils.defaultRunManual(frame, Squad, SquadUtils.defaultRow(SquadRow))
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return SquadUtils.defaultRunAuto(players, squadStatus, squadType, Squad, SquadUtils.defaultRow(SquadRow), customTitle)
end

return CustomSquad
