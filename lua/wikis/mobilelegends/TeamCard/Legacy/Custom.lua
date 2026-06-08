---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local InGameRoles = Lua.import('Module:InGameRoles', {loadData = true})
local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DEFAULT_MAX_PLAYER_INDEX = 10
local LANE_COUNT = 5
local INGAME_ROLES_BY_ORDER = Table.map(InGameRoles, function(_, roleData)
	return roleData.sortOrder, roleData.display
end)

local CustomLegacyTeamCard = {}

-- Template entry point
---@return Widget
function CustomLegacyTeamCard.run()
	return LegacyTeamCard.run(CustomLegacyTeamCard)
end

---@param card table
---@return table
function CustomLegacyTeamCard.preprocessCard(card)
	Array.forEach(Array.range(1, DEFAULT_MAX_PLAYER_INDEX), function(index)
		local key = 'p' .. index
		card[key .. 'pos'] = Logic.emptyOr(
			card[key .. 'pos'],
			Table.extract(card, 'pos' .. index),
			-- Only the five lane slots get a slot-index role default;
			-- non-lane roles (e.g. flex) must not auto-fill higher slots
			index <= LANE_COUNT and INGAME_ROLES_BY_ORDER[index] or nil
		)
	end)

	for tabIndex = 2, 3 do
		Array.forEach(Array.range(1, DEFAULT_MAX_PLAYER_INDEX), function(index)
			local key = 't' .. tabIndex .. 'p' .. index
			card[key .. 'pos'] = Logic.emptyOr(
				card[key .. 'pos'],
				Table.extract(card, 't' .. tabIndex .. 'pos' .. index)
			)
		end)
	end

	return card
end

return CustomLegacyTeamCard
