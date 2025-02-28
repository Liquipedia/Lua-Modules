---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TiebreakerFactory = {}

---@param name string
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromName(name)
	---@type StandingsTiebreaker?
	local tiebreakerClass
	if name == 'manual' then
		tiebreakerClass = Lua.import('Module:Standings/Tiebreaker/Manual')
	elseif name == 'points' then
		tiebreakerClass = Lua.import('Module:Standings/Tiebreaker/Points')
	elseif name == 'match.diff' then
		tiebreakerClass = Lua.import('Module:Standings/Tiebreaker/Match/Diff')
	else
		error("Invalid tiebreaker type: " .. tostring(name))
	end

	return tiebreakerClass
end

return TiebreakerFactory
