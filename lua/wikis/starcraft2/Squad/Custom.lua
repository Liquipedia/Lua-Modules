---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Squad = Lua.import('Module:Squad/Controller')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param squadData SquadWrapper
---@param squadPlayer ModelRow
local function adjustLpdb(squadData, squadPlayer)
	if squadData.squadStatus ~= SquadUtils.SquadStatus.ACTIVE then
		return
	end
	local isMain = Logic.readBool(squadData.args.main) or Logic.isEmpty(squadData.args.squad)
	squadPlayer.extradata.group = isMain and 'main' or 'additional'
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	return Squad.run(frame, adjustLpdb)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return Squad.runAuto(players, squadStatus, squadType, customTitle, adjustLpdb)
end

return CustomSquad
