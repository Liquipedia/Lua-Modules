---
-- @Liquipedia
-- wiki=clashroyale
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

	local opponentHeight = math.max(
		CustomBracketDisplay.computeBracketOpponentHeight(bracket.matchesById),
		props.config.opponentHeight or -1
	)

	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			opponentHeight = opponentHeight ~= -1 and opponentHeight or nil,
		})
	})
end

local defaultOpponentHeights = {
	duo = 2 * 17 + 6 + 4,
}
function CustomBracketDisplay.computeBracketOpponentHeight(matchesById)
	local maxHeight = -1
	for _, match in pairs(matchesById) do
		for _, opponent in ipairs(match.opponents) do
			maxHeight = math.max(maxHeight, defaultOpponentHeights[opponent.type] or -1)
		end
	end
	return maxHeight
end

return CustomBracketDisplay
