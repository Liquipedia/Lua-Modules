---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

-- Main-tab rows are always drivers. The old TC defaulted them to the Driver icon
-- by slot index via iconModule; the role-string pipeline needs an explicit role.
-- Requires `driver` in Module:Roles and a `['driver']` key in Module:PositionIcon/data.
local DEFAULT_DRIVER_ROLE = 'driver'
local DEFAULT_MAX_PLAYER_INDEX = 10

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
			DEFAULT_DRIVER_ROLE
		)
	end)

	return card
end

return CustomLegacyTeamCard
