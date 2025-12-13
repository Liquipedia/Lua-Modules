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
	roundwins = 'Game/Round/Wins',
	rounddiff = 'Game/Round/Diff',
}

--- Validates and normalizes the name of a tiebreaker input.
---@param input string
---@return string
function TiebreakerFactory.validateAndNormalizeInput(input)
	local context, name = unpack(String.split(input, '%.'))
	if name == nil then
		name = context
		context = 'full'
	end
	assert(
		context == 'full' or context == 'ml' or context == 'h2h',
		'Invalid tie breaker context: ' .. context
	)

	local tiebreakerClassName = NAME_TO_CLASS[name]
	assert(tiebreakerClassName, "Invalid tiebreaker type: " .. tostring(input))
	return table.concat({context, name}, '.')
end

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

return TiebreakerFactory
