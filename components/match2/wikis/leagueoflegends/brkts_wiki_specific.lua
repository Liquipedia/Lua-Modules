---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base'))

--
-- Override functons
--
function WikiSpecific.matchHasDetails(match)
	return Lua.import('Module:MatchGroup/Display/Helper').defaultMatchHasDetails or
		Lua.import('Module:BigMatch').isEnabledFor(match)
end

return WikiSpecific
