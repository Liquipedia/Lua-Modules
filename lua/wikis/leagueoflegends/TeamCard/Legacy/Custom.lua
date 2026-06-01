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
local INGAME_ROLES_BY_ORDER = Table.map(InGameRoles, function (_, roleData)
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
	-- Add local template override
	card.t3title = Logic.emptyOr(card.t3title, 'Staff')

	-- Adjust position arguments and add default
	Array.forEach(Array.range(1, DEFAULT_MAX_PLAYER_INDEX), function(index)
		local key = 'p' .. index
		card[key .. 'pos'] = Logic.emptyOr(
			card[key .. 'pos'],
			Table.extract(card, 'pos' .. index),
			INGAME_ROLES_BY_ORDER[index]
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
