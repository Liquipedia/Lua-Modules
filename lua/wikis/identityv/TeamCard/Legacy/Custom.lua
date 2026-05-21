---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local MAX_PLAYER_INDEX = 10

local POSITION_ALIASES = {
	s = 'survivor',
	h = 'hunter',
}

local CustomLegacyTeamCard = {}

-- Template entry point
---@return Widget
function CustomLegacyTeamCard.run()
	return LegacyTeamCard.run(CustomLegacyTeamCard)
end

---@param tcArgs table
---@return table
function CustomLegacyTeamCard.preprocessCard(tcArgs)
	for n = 1, MAX_PLAYER_INDEX do
		local oldKey = 'pos' .. n
		local value = tcArgs[oldKey]
		if Logic.isNotEmpty(value) then
			tcArgs['p' .. n .. 'pos'] = POSITION_ALIASES[value:lower()] or value
			tcArgs[oldKey] = nil
		end
	end
	return tcArgs
end

return CustomLegacyTeamCard
