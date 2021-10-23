---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Matchlist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local ErrorDisplay = require('Module:Error/Display')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local matchHasDetailsWikiSpecific = require('Module:Brkts/WikiSpecific').matchHasDetails

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local MatchlistDisplay = {propTypes = {}, types = {}}

MatchlistDisplay.configFromArgs = function(args)
	return {
		attached = Logic.readBoolOrNil(args.attached),
		collapsed = Logic.readBoolOrNil(args.collapsed),
		collapsible = not Logic.readBoolOrNil(args.nocollapse),
		width = tonumber(string.gsub(args.width or '', 'px', ''), nil),
	}
end

MatchlistDisplay.types.MatchlistConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	Opponent = 'function',
	Score = 'function',
	attached = 'boolean',
	collapsed = 'boolean',
	collapsible = 'boolean',
	matchHasDetails = 'function',
	width = 'number',
})
MatchlistDisplay.types.MatchlistConfigOptions = TypeUtil.struct(
	Table.mapValues(MatchlistDisplay.types.MatchlistConfig.struct, TypeUtil.optional)
)

MatchlistDisplay.propTypes.MatchlistContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(MatchlistDisplay.types.MatchlistConfigOptions),
}

--[[
Display component for a tournament matchlist. The matchlist is specified by ID.
The component fetches the match data from LPDB or page variables.
]]
function MatchlistDisplay.MatchlistContainer(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.MatchlistContainer)
	return MatchlistDisplay.Matchlist({
		config = props.config,
		matches = MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

MatchlistDisplay.propTypes.Matchlist = {
	config = TypeUtil.optional(MatchlistDisplay.types.MatchlistConfigOptions),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
}

--[[
Display component for a tournament matchlist. Match data is specified in the
input.
]]
function MatchlistDisplay.Matchlist(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Matchlist)

	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		Opponent = propsConfig.Opponent or MatchlistDisplay.Opponent,
		Score = propsConfig.Score or MatchlistDisplay.Score,
		attached = propsConfig.attached or false,
		collapsed = propsConfig.collapsed or false,
		collapsible = Logic.nilOr(propsConfig.collapsible, true),
		matchHasDetails = propsConfig.matchHasDetails or matchHasDetailsWikiSpecific or DisplayHelper.defaultMatchHasDetails,
		width = propsConfig.width or 300,
	}

	local matchlistNode = mw.html.create('div'):addClass('brkts-matchlist')
		:addClass(config.collapsible and 'brkts-matchlist-collapsible' or nil)
		:addClass(config.collapsed and 'brkts-matchlist-collapsed' or nil)
		:addClass(config.attached and 'brkts-matchlist-attached' or nil)
		:css('width', config.width .. 'px')

	for index, match in ipairs(props.matches) do
		local titleNode = index == 1
			and MatchlistDisplay.Title({
				title = match.bracketData.title or 'Match List',
			})
			or nil

		local headerNode = match.bracketData.header
			and MatchlistDisplay.Header({
				header = match.bracketData.header,
			})
			or nil

		local matchNode = MatchlistDisplay.Match({
			MatchSummaryContainer = config.MatchSummaryContainer,
			Opponent = config.Opponent,
			Score = config.Score,
			match = match,
			matchHasDetails = config.matchHasDetails,
		})

		matchlistNode:node(titleNode):node(headerNode):node(matchNode)
	end

	return matchlistNode
end

MatchlistDisplay.propTypes.Match = {
	MatchSummaryContainer = 'function',
	Opponent = 'function',
	Score = 'function',
	match = MatchGroupUtil.types.Match,
	matchHasDetails = 'function',
}

--[[
Display component for a match in a matchlist. Consists of two opponents, two
scores, and a icon for the match summary popup.
]]
function MatchlistDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Match)
	local match = props.match

	local function renderOpponent(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local opponentNode = DisplayUtil.tryOrLog(props.Opponent, {
			opponent = opponent,
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
		})
			or mw.html.create('div'):addClass('brkts-matchlist-cell')
		return DisplayHelper.addOpponentHighlight(opponentNode, opponent)
	end

	local function renderScore(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local scoreNode = DisplayUtil.tryOrLog(props.Score, {
			opponent = opponent,
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
		})
			or mw.html.create('div'):addClass('brkts-matchlist-cell')
		return DisplayHelper.addOpponentHighlight(scoreNode, opponent)
	end

	local matchInfoIconNode
	local matchSummaryNode
	if props.matchHasDetails(match) then
		local bracketId, _ = MatchGroupUtil.splitMatchId(match.matchId)
		matchInfoIconNode = mw.html.create('div'):addClass('brkts-match-info-icon')
		matchSummaryNode = DisplayUtil.tryOrElseLog(
			props.MatchSummaryContainer,
			{bracketId = bracketId, matchId = match.matchId},
			ErrorDisplay.ErrorDetails
		)
			:addClass('brkts-match-info-popup')
	else
		matchInfoIconNode = mw.html.create('div'):addClass('brkts-matchlist-placeholder-cell')
	end

	return mw.html.create('div'):addClass('brkts-matchlist-match')
		:addClass(matchSummaryNode and 'brkts-match-has-details brkts-match-popup-wrapper' or nil)
		:node(renderOpponent(1))
		:node(renderScore(1))
		:node(matchInfoIconNode)
		:node(renderScore(2))
		:node(renderOpponent(2))
		:node(matchSummaryNode)
end

MatchlistDisplay.propTypes.Title = {
	title = 'string',
}

--[[
Display component for a title in a matchlist.
]]
function MatchlistDisplay.Title(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Title)
	local titleNode = mw.html.create('div'):addClass('brkts-matchlist-title')
		:wikitext(props.title)

	return DisplayUtil.applyOverflowStyles(titleNode, 'wrap')
end

MatchlistDisplay.propTypes.Header = {
	header = 'string',
}

--[[
Display component for a header in a matchlist.
]]
function MatchlistDisplay.Header(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Header)

	local headerNode = mw.html.create('div'):addClass('brkts-matchlist-header')
		:wikitext(props.header)

	return DisplayUtil.applyOverflowStyles(headerNode, 'wrap')
end

--[[
Display component for an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Opponent to the Matchlist
component.
]]
function MatchlistDisplay.Opponent(props)
	local contentNode = OpponentDisplay.BlockOpponent({
		flip = props.side == 'left',
		opponent = props.opponent,
		overflow = 'ellipsis',
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

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component.
]]
function MatchlistDisplay.Score(props)
	local contentNode = mw.html.create('div'):addClass('brkts-matchlist-cell-content')
		:node(OpponentDisplay.InlineScore(props.opponent))
	return mw.html.create('div')
		:addClass('brkts-matchlist-cell brkts-matchlist-score')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return Class.export(MatchlistDisplay)
