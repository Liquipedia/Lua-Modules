---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})

local CustomBracketDisplay = {}

---@param props {bracketId: string, config: table}
---@return Html
function CustomBracketDisplay.BracketContainer(props)
	local bracket = CustomMatchGroupUtil.fetchMatchGroup(props.bracketId)
	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			matchHasDetails = CustomMatchGroupUtil.matchHasDetails,
		})
	})
end

return CustomBracketDisplay
