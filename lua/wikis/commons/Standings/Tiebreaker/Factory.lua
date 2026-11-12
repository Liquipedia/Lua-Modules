---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local TiebreakerFactory = {}

---@type table<string, string>
local NAME_TO_CLASS = {
	buchholz = 'Buchholz',
	medianbuchholz = 'MedianBuchholz',
	buchholzcutone = 'BuchholzCutOne',
	buchholzpoints = 'BuchholzPoints',
	medianbuchholzpoints = 'MedianBuchholzPoints',
	buchholzcutonepoints = 'BuchholzCutOnePoints',
	sonnebornberger = 'SonnebornBerger',
	disqualified = 'Disqualified',
	manual = 'Manual',
	points = 'Points',
	matchdiff = 'Match/Diff',
	matchcount = 'Match/Count',
	matchwins = 'Match/Wins',
	matchdraws = 'Match/Draws',
	matchlosses = 'Match/Losses',
	matchwinrate = 'Match/WinRate',
	matchscore = 'Match/Score',
	gamediff = 'Game/Diff',
	gamecount = 'Game/Count',
	gamewins = 'Game/Wins',
	gamelosses = 'Game/Losses',
	gamewinrate = 'Game/WinRate',
	gamescore = 'Game/Score',
	roundwins = 'Game/Rounds/Wins',
	roundlosses = 'Game/Rounds/Losses',
	rounddiff = 'Game/Rounds/Diff',
	roundwinrate = 'Game/Rounds/WinRate',
	roundscore = 'Game/Rounds/Score',
	startingpoints = 'StartingPoints',
}

-- Game tiebreakers and their match counterpart
---@type table<string, string>
local GAME_TO_MATCH = {
	gamescore = 'matchscore',
	gamewins = 'matchwins',
	gamelosses = 'matchlosses',
	gamecount = 'matchcount',
	gamediff = 'matchdiff',
	gamewinrate = 'matchwinrate',
}

---@param name string?
---@return StandingsTiebreaker?
local function getTiebreakerClass(name)
	local tiebreakerClassName = name and NAME_TO_CLASS[name]
	if not tiebreakerClassName then
		return nil
	end
	return Lua.import('Module:Standings/Tiebreaker/' .. tiebreakerClassName)
end

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

	local TiebreakerClass = getTiebreakerClass(name)
	assert(TiebreakerClass, "Invalid tiebreaker type: " .. tostring(input))
	assert(
		context == 'full' or not TiebreakerClass.fullContextOnly,
		'Tiebreaker "' .. name .. '" cannot be used in the ' .. context .. ' context, '
			.. 'as it is not derived from the matches among the tied opponents'
	)
	return table.concat({context, name}, '.')
end

---@param tiebreakerId string
---@return boolean
function TiebreakerFactory.readsGames(tiebreakerId)
	local _, name = TiebreakerFactory.parseId(tiebreakerId)
	local TiebreakerClass = getTiebreakerClass(name)
	return TiebreakerClass ~= nil and TiebreakerClass.readsGames
end

--- Whether the value only depends on the match record and points of the opponent, which needs the full context.
---@param tiebreakerId string
---@return boolean
function TiebreakerFactory.isMatchRecordOnly(tiebreakerId)
	local context, name = TiebreakerFactory.parseId(tiebreakerId)
	local TiebreakerClass = getTiebreakerClass(name)
	return context == 'full' and TiebreakerClass ~= nil and TiebreakerClass.matchRecordOnly
end

--- The match counterpart of a game tiebreaker, other tiebreakers are returned unchanged.
---@param tiebreakerId string
---@return string
function TiebreakerFactory.toMatchEquivalent(tiebreakerId)
	local context, name = TiebreakerFactory.parseId(tiebreakerId)
	local matchName = name and GAME_TO_MATCH[name]
	if not matchName then
		return tiebreakerId
	end
	return table.concat({context, matchName}, '.')
end

---@param tiebreakerId string
---@param options StandingsTiebreakerOptions?
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromId(tiebreakerId, options)
	local context, name = TiebreakerFactory.parseId(tiebreakerId)
	local TiebreakerClass = getTiebreakerClass(name)
	assert(TiebreakerClass, "Invalid tiebreaker type: " .. tostring(tiebreakerId))
	return TiebreakerClass(context, options)
end

return TiebreakerFactory
