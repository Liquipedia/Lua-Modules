---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Matchlist/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchlistDisplay = Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true})
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})
local StarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})

local StarcraftMatchlistDisplay = {}

function StarcraftMatchlistDisplay.MatchlistContainer(props, matches)
	return MatchlistDisplay.Matchlist({
		config = Table.merge(props.config, {
			MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer,
			Opponent = StarcraftMatchlistDisplay.Opponent,
			Score = StarcraftMatchlistDisplay.Score,
		}),
		matches = matches or MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

function StarcraftMatchlistDisplay.Opponent(props)
	local contentNode = StarcraftOpponentDisplay.BlockOpponent({
		flip = props.side == 'left',
		opponent = props.opponent,
		overflow = 'ellipsis',
		showFlag = false,
		showLink = false,
		teamStyle = 'short',
	})
		:addClass('brkts-matchlist-cell-content')
	return mw.html.create('div')
		:addClass('brkts-matchlist-cell brkts-matchlist-opponent')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil)
		:addClass(props.resultType == 'draw' and 'brkts-matchlist-slot-bold bg-draw' or nil)
		:node(contentNode)
end

function StarcraftMatchlistDisplay.Score(props)
	local contentNode = mw.html.create('div'):addClass('brkts-matchlist-cell-content')
		:node(StarcraftOpponentDisplay.InlineScore(props.opponent))
	return mw.html.create('div')
		:addClass('brkts-matchlist-cell brkts-matchlist-score')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return StarcraftMatchlistDisplay
