---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local CustomBracketDisplay = Table.copy(BracketDisplay)

function CustomBracketDisplay.BracketContainer(props)
	local bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId)
	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			opponentHeight = CustomBracketDisplay.computeBracketOpponentHeight(bracket.matchesById),
		})
	})
end

local defaultOpponentHeights = {
	default = 17 + 6,
	duo = 2 * 17 + 6 + 4,
}
function CustomBracketDisplay.computeBracketOpponentHeight(matchesById)
	local maxHeight = defaultOpponentHeights.default

	for _, match in pairs(matchesById) do
		for _, opponent in ipairs(match.opponents) do
			maxHeight = math.max(maxHeight, defaultOpponentHeights[opponent.type] or 0)
		end
	end

	return maxHeight
end

return CustomBracketDisplay
