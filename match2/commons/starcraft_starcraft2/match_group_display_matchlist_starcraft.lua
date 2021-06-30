local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local MatchlistDisplay = require('Module:MatchGroup/Display/Matchlist')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local StarcraftOpponentDisplay = require('Module:OpponentDisplay/Starcraft')
local Table = require('Module:Table')

local html = mw.html

local StarcraftMatchlistDisplay = {}

function StarcraftMatchlistDisplay.luaGet(_, args)
	return StarcraftMatchlistDisplay.MatchlistContainer({
		bracketId = args[1],
		config = MatchlistDisplay.configFromArgs(args),
	})
end

function StarcraftMatchlistDisplay.MatchlistContainer(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.MatchlistContainer)
	return StarcraftMatchlistDisplay.Matchlist({
		config = props.config,
		matches = MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

function StarcraftMatchlistDisplay.Matchlist(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Matchlist)
	return MatchlistDisplay.Matchlist({
		config = Table.merge(props.config, {
			MatchSummaryContainer = require('Module:MatchSummary/Starcraft').MatchSummaryContainer,
			Opponent = StarcraftMatchlistDisplay.Opponent,
			Score = StarcraftMatchlistDisplay.Score,
			matchHasDetails = StarcraftMatchGroupUtil.matchHasDetails,
		}),
		matches = props.matches,
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
		:css('width', props.width - 2 * MatchlistDisplay.cellPadding - 1 .. 'px')
	return html.create('td')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil)
		:addClass(props.resultType == 'draw' and 'brkts-matchlist-slot-bold bg-draw' or nil)
		:node(contentNode)
end

function StarcraftMatchlistDisplay.Score(props)
	local contentNode = html.create('div'):addClass('brkts-matchlist-score')
		:node(StarcraftOpponentDisplay.InlineScore(props.opponent))
		:css('width', props.width - 2 * MatchlistDisplay.cellPadding - 1 .. 'px')
	return html.create('td')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return Class.export(StarcraftMatchlistDisplay)
