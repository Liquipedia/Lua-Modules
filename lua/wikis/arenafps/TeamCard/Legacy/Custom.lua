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

local Custom = {}

---@param tcArgs table
function Custom.preprocessCard(tcArgs)
	local teamPlayers = Variables.varDefault('tournament_teamplayers')
	if Logic.isNotEmpty(teamPlayers) then
		tcArgs.defaultRowNumber = teamPlayers
	end
end

---@return Widget
function Custom.run()
	return LegacyTeamCard.run({preprocessCard = Custom.preprocessCard})
end

return Custom
