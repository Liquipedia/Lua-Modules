---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Api/Import
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Import = {}

---@param matchGroupSpec MatchGroupsSpec
---@return match2[]
function Import.fromMatchGroupSpec(matchGroupSpec)
	if Logic.isEmpty(matchGroupSpec) then
		return {}
	end
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(TournamentStructure.getMatch2Filter(matchGroupSpec)),
		query = 'pagename, match2bracketdata, match2opponents, winner',
		order = 'date asc',
		limit = 5000,
	})
end

return Import
