---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class TrackmaniaBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

function WikiSpecific.getMatchGroupContainer(matchGroupType, maxOpponentCount)
	if maxOpponentCount > 4 or (maxOpponentCount > 2 and matchGroupType == 'matchlist') then
		local Horizontallist = Lua.import('Module:MatchGroup/Display/Horizontallist')
		return Horizontallist.BracketContainer
	elseif matchGroupType == 'matchlist' then
		local MatchList = Lua.import('Module:MatchGroup/Display/Matchlist')
		return MatchList.MatchlistContainer
	end

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket/Custom')
	return Bracket.BracketContainer
end

return WikiSpecific
