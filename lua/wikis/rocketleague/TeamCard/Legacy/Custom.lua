---
-- @Liquipedia
-- page=Module:TeamCard/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local FIRST_SUB_INDEX = 4
local LAST_SUB_INDEX = 12
local MAX_FORMER_INDEX = 7
local FORMER_FLAG_OFFSET = 5

local CustomLegacyTeamCard = {}

-- Template entry point
---@return Widget
function CustomLegacyTeamCard.run()
	return LegacyTeamCard.run(CustomLegacyTeamCard)
end

---@param n integer
---@return string
local function formerKey(n)
	return n == 1 and 'ex' or ('ex' .. n)
end

---@param card table
---@return table
function CustomLegacyTeamCard.preprocessCard(card)
	-- Subs 1-3 are variants of the starting players: fill an empty starter slot and
	-- flag it as a substitute. The old template used a `pos="<abbr>S</abbr>"` hack plus
	-- inverted `dnp` strings; the new pipeline marks subs via `pNsub`/`pNresult`.
	for n = 1, 3 do
		local sub = card['sub' .. n]
		if Logic.isNotEmpty(sub) then
			card['p' .. n] = Logic.emptyOr(card['p' .. n], sub)
			card['p' .. n .. 'sub'] = 'true'
			card['p' .. n .. 'result'] = card['sub' .. n .. '_played']
			card['sub' .. n] = nil
		end
	end

	-- Subs 4-12 are regular substitutes (s-group). Flag/link borrow the matching pN slot,
	-- mirroring the old `|sNflag={{{pNflag}}}` wiring. `subdnpdefault` is honored natively
	-- by Module:TeamCard/Legacy for the s-group, so an empty result defaults to did-not-play.
	for n = FIRST_SUB_INDEX, LAST_SUB_INDEX do
		local sub = card['sub' .. n]
		if Logic.isNotEmpty(sub) then
			card['s' .. n] = sub
			card['s' .. n .. 'flag'] = card['p' .. n .. 'flag']
			card['s' .. n .. 'link'] = card['p' .. n .. 'link']
			card['s' .. n .. 'result'] = card['sub' .. n .. '_played']
			card['sub' .. n] = nil
		end
	end

	-- Former players (ex, ex2..ex7) → f-group. Flag/link borrow pN starting at p6, mirroring
	-- the old `|fNflag={{{p(N+5)flag}}}` wiring. The old template set `formerdnpdefault=true`,
	-- which Module:TeamCard/Legacy does not honor, so default the former to did-not-play here.
	for n = 1, MAX_FORMER_INDEX do
		local key = formerKey(n)
		local former = card[key]
		if Logic.isNotEmpty(former) then
			card['f' .. n] = former
			card['f' .. n .. 'flag'] = card['p' .. (n + FORMER_FLAG_OFFSET) .. 'flag']
			card['f' .. n .. 'link'] = card['p' .. (n + FORMER_FLAG_OFFSET) .. 'link']
			local played = card[key .. '_played']
			card['f' .. n .. 'result'] = played
			if Logic.isEmpty(played) then
				card['f' .. n .. 'dnp'] = 'true'
			end
			card[key] = nil
		end
	end

	return card
end

return CustomLegacyTeamCard
