---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Tiebreaker/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TiebreakerFactory = {}

---@param name string
---@return StandingsTiebreaker
function TiebreakerFactory.tiebreakerFromName(name)
	---@type StandingsTiebreaker?
	local tiebreakerClass
	if name == 'manual' then
		tiebreakerClass = require('Module:Standings/Tiebreaker/Manual')
	elseif name == 'points' then
		tiebreakerClass = require('Module:Standings/Tiebreaker/Points')
	elseif name == 'match.diff' then
		tiebreakerClass = require('Module:Standings/Tiebreaker/Match/Diff')
	else
		error("Invalid tiebreaker type: " .. tostring(name))
	end

	return tiebreakerClass()
end

return TiebreakerFactory
