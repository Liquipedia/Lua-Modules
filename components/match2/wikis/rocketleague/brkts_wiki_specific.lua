---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base'))

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist').MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom').BracketContainer
end

WikiSpecific.defaultIcon = 'Rllogo_std.png'

return WikiSpecific
