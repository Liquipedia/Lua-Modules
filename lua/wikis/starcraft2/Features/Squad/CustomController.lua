---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local SquadController = Lua.import('Module:Features/Squad/Controller')

local CustomSquad = {}

local function adjustLpdb(squadData, squadPlayer)
	if not squadData.squadStatus == SquadUtils.SquadStatus.ACTIVE then
		return
	end
	local isMain = Logic.readBool(squadData.main) or Logic.isEmpty(squadData.squad)
	squadPlayer.extradata.group = isMain and 'main' or 'additional'
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	return SquadController.run(frame, adjustLpdb)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return SquadController.runAuto(players, squadStatus, squadType, customTitle, adjustLpdb)
end

return CustomSquad
