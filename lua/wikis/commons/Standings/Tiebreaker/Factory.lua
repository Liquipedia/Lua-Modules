---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local TiebreakerFactory = {}

local NAME_TO_CLASS = {
	buchholz = 'Buchholz',
	disqualified = 'Disqualified',
	manual = 'Manual',
	points = 'Points',
	matchdiff = 'Match/Diff',
	matchcount = 'Match/Count',
	matchwins = 'Match/Wins',
	matchdraws = 'Match/Draws',
	matchlosses = 'Match/Losses',
	matchwinrate = 'Match/WinRate',
	gamediff = 'Game/Diff',
	gamecount = 'Game/Count',
	gamewins = 'Game/Wins',
	gamelosses = 'Game/Losses',
	gamewinrate = 'Game/WinRate',
	roundwins = 'Game/Rounds/Wins',
	roundlosses = 'Game/Rounds/Losses',
	rounddiff = 'Game/Rounds/Diff',
	startingpoints = 'StartingPoints',
}

-- Tiebreakers that are not derived from the matches among tied opponents, so they only exist in the full context
local NON_MATCH_BASED = {
	buchholz = true,
	manual = true,
	disqualified = true,
	startingpoints = true,
}

--- Splits a tiebreaker id into its context and name.
--- Input without a context (e.g. `points`) only has a first part, which then is the name.
---@param tiebreakerId string
---@return string context, string? name
function TiebreakerFactory.parseId(tiebreakerId)
	local context, name = unpack(String.split(tiebreakerId, '%.'))
	return context, name
end

--- Validates and normalizes the name of a tiebreaker input.
---@param input string
---@return string
function TiebreakerFactory.validateAndNormalizeInput(input)
	local context, name = TiebreakerFactory.parseId(input)
	if name == nil then
		name = context
		context = 'full'
	end
	assert(
		context == 'full' or context == 'ml' or context == 'h2hcs' or context == 'h2hlegacy',
		'Invalid tie breaker context: ' .. context
	)

	local tiebreakerClassName = NAME_TO_CLASS[name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(input))
	assert(
		context == 'full' or not NON_MATCH_BASED[name],
		'Tiebreaker "' .. name .. '" cannot be used in the ' .. context .. ' context, '
			.. 'as it is not derived from the matches among the tied opponents'
	)
	return table.concat({context, name}, '.')
end

---@param tiebreakerId string
---@param options StandingsTiebreakerOptions?
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromId(tiebreakerId, options)
	local context, name = TiebreakerFactory.parseId(tiebreakerId)
	local tiebreakerClassName = NAME_TO_CLASS[name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(tiebreakerId))
	---@type StandingsTiebreaker
	local TiebreakerClass = Lua.import('Module:Standings/Tiebreaker/' .. tiebreakerClassName)

	return TiebreakerClass(context, options)
end

return TiebreakerFactory
