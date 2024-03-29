---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
local CustomOpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local CustomBracketDisplay = {propTypes = {}}

function CustomBracketDisplay.BracketContainer(props)
	return BracketDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		config = Table.merge(props.config, {
			OpponentEntry = CustomBracketDisplay.OpponentEntry,
		})
	})
end

function CustomBracketDisplay.OpponentEntry(props)
	local opponentEntry = CustomOpponentDisplay.BracketOpponentEntry(props.opponent)
	if props.displayType == 'bracket' then
		opponentEntry:addScores(props.opponent)
	end
	return opponentEntry.root
end

return Class.export(CustomBracketDisplay)
