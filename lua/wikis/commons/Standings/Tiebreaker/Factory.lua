---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local TiebreakerFactory = {}

---@class ParsedTiebreaker
---@field name string
---@field context string
---@field id string
---@field config table?

local NAME_TO_CLASS = {
	buchholz = 'Buchholz',
	manual = 'Manual',
	points = 'Points',
	matchdiff = 'Match/Diff',
	matchcount = 'Match/Count',
	matchwins = 'Match/Wins',
	matchdraws = 'Match/Draws',
	matchwinrate = 'Match/WinRate',
	gamediff = 'Game/Diff',
	gamecount = 'Game/Count',
	gamewins = 'Game/Wins',
	gamedraws = 'Game/Draws',
	gamewinrate = 'Game/WinRate',
}

---@param input string|table
---@return ParsedTiebreaker
function TiebreakerFactory._parseTiebreakerInput(input)
	if type(input) == 'table' then
		local tiebreakerName = Table.extract(input, 'name')
		local tiebreakerContext = Logic.emptyOr(Table.extract(input, 'context'), 'full')
		return {
			name = tiebreakerName,
			context = tiebreakerContext,
			id = tiebreakerContext .. tiebreakerName,
			config = Logic.nilIfEmpty(input)
		}
	end
	local context, name = unpack(String.split(input, '%.'))
	if name == nil then
		name = context
		context = 'full'
	end
	return {
		name = name,
		context = context,
		id = context .. name,
	}
end

--- Validates and normalizes the name of a tiebreaker input.
---@param input string|table
---@return ParsedTiebreaker
function TiebreakerFactory.validateAndNormalizeInput(input)
	local parsedInput = TiebreakerFactory._parseTiebreakerInput(input)
	assert(
		parsedInput.context == 'full' or parsedInput.context == 'ml' or parsedInput.context == 'h2h',
		'Invalid tie breaker context: ' .. parsedInput.context
	)

	local tiebreakerClassName = NAME_TO_CLASS[parsedInput.name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(input))
	return parsedInput
end

---@deprecated
---@param tiebreakerId string
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromId(tiebreakerId)
	local context, name = unpack(String.split(tiebreakerId, '%.'))
	local tiebreakerClassName = NAME_TO_CLASS[name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(tiebreakerId))
	---@type StandingsTiebreaker
	local TiebreakerClass = Lua.import('Module:Standings/Tiebreaker/' .. tiebreakerClassName)

	return TiebreakerClass(context)
end

---@param parsedTiebreaker ParsedTiebreaker
---@return StandingsTiebreaker
function TiebreakerFactory.getTiebreaker(parsedTiebreaker)
	local tiebreakerClassName = NAME_TO_CLASS[parsedTiebreaker.name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(parsedTiebreaker.name))
	---@type StandingsTiebreaker
	local TiebreakerClass = Lua.import('Module:Standings/Tiebreaker/' .. tiebreakerClassName)

	return TiebreakerClass(parsedTiebreaker.context, parsedTiebreaker.config)
end


return TiebreakerFactory
