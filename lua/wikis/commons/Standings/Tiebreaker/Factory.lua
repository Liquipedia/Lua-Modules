---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local TiebreakerFactory = {}

local NAME_TO_CLASS = {
	manual = 'Manual',
	points = 'Points',
	matchdiff = 'Match/Diff',
	buchholz = 'Buchholz',
}

---@param input string
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromName(input)
	local context, name = unpack(String.split(input, '%.'))
	if name == nil then
		name = context
		context = 'full'
	end
	assert(
		context == 'full' or context == 'ml' or context == 'h2h',
		'Invalid tie breaker context: ' .. context
	)

	local className = NAME_TO_CLASS[name]
	assert(className, "Invalid tiebreaker type: " .. tostring(name))

	---@type StandingsTiebreaker
	local tiebreakerClass = Lua.import('Module:Standings/Tiebreaker/' .. className)

	return tiebreakerClass(context)
end

return TiebreakerFactory
