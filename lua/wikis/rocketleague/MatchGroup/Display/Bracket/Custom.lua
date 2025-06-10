---
-- @Liquipedia
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
local CustomOpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomBracketDisplay = {propTypes = {}}

---@param props {bracketId: string, config: BracketConfigOptions}
---@return Html
function CustomBracketDisplay.BracketContainer(props)
	return BracketDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId) --[[@as MatchGroupUtilBracket]],
		config = Table.merge(props.config, {
			OpponentEntry = CustomBracketDisplay.OpponentEntry,
		})
	})
end

---@param props {opponent: standardOpponent, displayType: string, forceShortName: boolean?, height: number}
---@return Html
function CustomBracketDisplay.OpponentEntry(props)
	local opponentEntry = CustomOpponentDisplay.BracketOpponentEntry(props.opponent)
	if props.displayType == 'bracket' then
		opponentEntry:addScores(props.opponent)
	end
	return opponentEntry.root
end

return CustomBracketDisplay
