---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DEFAULT_MAX_PLAYER_INDEX = 10
local LANE_COUNT = 5
-- Default lane role per slot, indexed by InGameRoles sortOrder. These are the canonical
-- role *keys* (not displays): RoleUtil lowercases the position and looks it up in both
-- Roles.All and PositionIcon/data, so the value must be a real key. mlbb displays
-- ('EXP Laner', 'Mid Laner', 'Gold Laner') don't match their keys, so feeding displays
-- back as positions fails to resolve and renders them as plain-text labels.
local LANE_ROLE_BY_ORDER = {'exp lane', 'jungler', 'middle', 'gold lane', 'roamer'}

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
			index <= LANE_COUNT and LANE_ROLE_BY_ORDER[index] or nil
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
