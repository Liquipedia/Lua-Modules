---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')
local OpponentEntry = Lua.import('Module:Widget/Match/Bracket/OpponentEntry/Custom')

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

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket')
	return WikiSpecific.adjustBracketContainerConfig(Bracket.BracketContainer)
end

---@param displayContainer fun(props: {bracketId: string, config: BracketConfigOptions}): Html
---@return fun(props: {bracketId: string, config: BracketConfigOptions}): Html
function WikiSpecific.adjustBracketContainerConfig(displayContainer)
	return function(props)
		local config = Table.merge(props.config or {}, {OpponentEntry = OpponentEntry})
		return displayContainer(Table.merge(props, {config = config}))
	end
end

return WikiSpecific
