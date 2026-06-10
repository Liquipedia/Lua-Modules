---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local DEFAULT_MAX_PLAYER_INDEX = 20

local CustomLegacyTeamCard = {}

-- Template entry point
---@return Widget
function CustomLegacyTeamCard.run()
	return LegacyTeamCard.run(CustomLegacyTeamCard)
end

---Resolves the player number for one dota2 roster slot.
---A numeric `pos` (the in-game position, 1-5) becomes the number and is dropped as a role;
---non-numeric markers (e.g. `S`) are left in place. `keys[1]` is the prefixed form
---(`p1pos`), `keys[2]` the commons group alias form (`pos1`). Precedence is
---presence-based, not numeric-based: a non-empty `keys[1]` shadows `keys[2]` even when
---non-numeric, matching how commons `mapPlayers` resolves the same alias.
---@param card table
---@param keys string[]
---@return integer?
local function extractPositionNumber(card, keys)
	local number = tonumber(Logic.emptyOr(card[keys[1]], card[keys[2]]))
	if number then
		card[keys[1]] = nil
		card[keys[2]] = nil
	end
	return number
end

---@param card table
---@return table
function CustomLegacyTeamCard.preprocessCard(card)
	-- Pin maxPlayers so this loop and commons mapPlayers share the same bound (commons defaults to 10).
	card.maxPlayers = tonumber(card.maxPlayers) or DEFAULT_MAX_PLAYER_INDEX
	local maxPlayerIndex = card.maxPlayers

	-- Main roster: number = explicit in-game position, else slot index.
	Array.forEach(Array.range(1, maxPlayerIndex), function(index)
		local key = 'p' .. index
		if Logic.isEmpty(card[key]) then return end
		local number = extractPositionNumber(card, {key .. 'pos', 'pos' .. index})
		card[key .. 'number'] = Logic.emptyOr(card[key .. 'number'], number, index)
	end)

	-- Additional tabs (t2/t3): number = explicit in-game position only (no slot-index default).
	for tabIndex = 2, 3 do
		Array.forEach(Array.range(1, maxPlayerIndex), function(index)
			local key = 't' .. tabIndex .. 'p' .. index
			if Logic.isEmpty(card[key]) then return end
			local number = extractPositionNumber(card, {key .. 'pos', 't' .. tabIndex .. 'pos' .. index})
			card[key .. 'number'] = Logic.emptyOr(card[key .. 'number'], number)
		end)
	end

	return card
end

return CustomLegacyTeamCard
