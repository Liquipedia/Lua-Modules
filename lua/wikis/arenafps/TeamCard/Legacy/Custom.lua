---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local CustomLegacyTeamCard = {}

-- Template entry point
---@return Widget
function CustomLegacyTeamCard.run()
	return LegacyTeamCard.run(CustomLegacyTeamCard)
end

---@param tcArgs table
---@return table
function CustomLegacyTeamCard.preprocessCard(tcArgs)
	local teamPlayers = Variables.varDefault('tournament_teamplayers')
	if Logic.isNotEmpty(teamPlayers) then
		tcArgs.defaultRowNumber = teamPlayers
	end
	return tcArgs
end

return CustomLegacyTeamCard
