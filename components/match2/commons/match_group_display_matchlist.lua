local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local OpponentDisplay = require('Module:OpponentDisplay')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local matchHasDetailsWikiSpecific = require('Module:Brkts/WikiSpecific').matchHasDetails

local html = mw.html

local MatchlistDisplay = {propTypes = {}, types = {}}

--[[
Horiziontal and vertical padding used by most cells in the matchlist
]]
MatchlistDisplay.cellPadding = 5

-- Called by MatchGroup/Display
function MatchlistDisplay.luaGet(_, args)
	return MatchlistDisplay.MatchlistContainer({
		bracketId = args[1],
		config = MatchlistDisplay.configFromArgs(args),
	})
end

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
	local tableNode = html.create('table')
		:addClass('brkts-matchlist wikitable wikitable-bordered matchlist')
		:addClass(config.collapsible and 'collapsible' or nil)
		:addClass(config.collapsed and 'collapsed' or nil)
		:addClass(config.attached and 'brkts-matchlist-attached' or nil)
		:css('margin-top', config.attached and '-1px' or nil)
		:css('width', config.width .. 'px')

	for index, match in ipairs(props.matches) do
		local titleNode = index == 1
			and MatchlistDisplay.Title({
				title = match.bracketData.title or 'Match List',
				width = config.width,
			})
			or nil

		local headerNode = match.bracketData.header
			and MatchlistDisplay.Header({
				header = match.bracketData.header,
				width = config.width,
			})
			or nil

		local matchNode = MatchlistDisplay.Match({
			MatchSummaryContainer = config.MatchSummaryContainer,
			Opponent = config.Opponent,
			Score = config.Score,
			match = match,
			matchHasDetails = config.matchHasDetails,
			width = config.width,
		})

		tableNode
			:node(titleNode)
			:node(headerNode)
			:node(matchNode)
	end

	return html.create('div'):addClass('brkts-main brkts-main-dev-2')
		:cssText(config.attached and 'padding-left:0px; padding-right:0px' or nil)
		:node(tableNode)
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

	-- Compute widths of the 2 opponent and 2 score columns. The small offsets
	-- are due to border splitting from table-layout: auto.
	local minScoreWidth = 30
	local scoreWidth = math.max(minScoreWidth, math.floor(0.1 * props.width))
	-- width of both opponent fields is total width -2 (border widths) - width of the score fields
	local opponentWidth = 0.5 * (props.width - 2 - (2 * scoreWidth))

	local renderOpponent = function(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local opponentNode = props.Opponent({
			opponent = opponent,
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
			width = opponentWidth,
		})
		return DisplayHelper.addOpponentHighlight(opponentNode, opponent)
	end

	local renderScore = function(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local scoreNode = props.Score({
			opponent = opponent,
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
			width = scoreWidth,
		})
		return DisplayHelper.addOpponentHighlight(scoreNode, opponent)
	end

	local matchSummaryPopupNode
	if props.matchHasDetails(match) then
		local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
			bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
			matchId = props.match.matchId,
		})

		matchSummaryPopupNode = html.create('div')
			:addClass('brkts-match-info-popup')
			:css('max-height', '80vh')
			:css('overflow', 'auto')
			:css('display', 'none')
			:node(matchSummaryNode)
	end

	local matchInfo = html.create('td')
		:addClass('brkts-match-info brkts-empty-td')
		:node(
			matchSummaryPopupNode
				and html.create('div'):addClass('brkts-match-info-icon')
				or nil
		)
		:node(matchSummaryPopupNode)

	return html.create('tr')
		:addClass('brtks-matchlist-row brkts-matchlist-row brkts-match-popup-wrapper')
		:css('cursor', 'pointer')
		:node(renderOpponent(1))
		:node(renderScore(1))
		:node(matchInfo)
		:node(renderScore(2))
		:node(renderOpponent(2))
end

MatchlistDisplay.propTypes.Title = {
	title = 'string',
}

--[[
Display component for a title in a matchlist.
]]
function MatchlistDisplay.Title(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Title)
	local titleNode = html.create('div')
		:css('width', (props.width - (2 * MatchlistDisplay.cellPadding) - 2) .. 'px')
		:wikitext(props.title)

	local thNode = html.create('th')
		:addClass('brkts-matchlist-title')
		:attr('colspan', '5')
		:node(DisplayUtil.applyOverflowStyles(titleNode, 'wrap'))
	return html.create('tr'):node(thNode)
end

MatchlistDisplay.propTypes.Header = {
	header = 'string',
}

--[[
Display component for a header in a matchlist.
]]
function MatchlistDisplay.Header(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Header)

	local headerNode = html.create('div')
		:css('width', (props.width - (2 * MatchlistDisplay.cellPadding) - 2) .. 'px')
		:wikitext(props.header)

	local thNode = html.create('th')
		:addClass('brkts-matchlist-header')
		:attr('colspan', '5')
		:css('line-height', 'unset')
		:css('padding', '1px 5px')
		:node(DisplayUtil.applyOverflowStyles(headerNode, 'wrap'))
	return html.create('tr'):node(thNode)
end

--[[
Display component for an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Opponent to the Matchlist
component. Custom implementations should ensure that the rendered width is
exactly props.width.
]]
function MatchlistDisplay.Opponent(props)
	local contentNode = OpponentDisplay.BlockOpponent({
		flip = props.side == 'left',
		opponent = props.opponent,
		overflow = 'ellipsis',
		showLink = false,
		teamStyle = 'short',
	})
		:css('width', (props.width - (2 * MatchlistDisplay.cellPadding) - 1) .. 'px')
	return html.create('td')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil)
		:addClass(props.resultType == 'draw' and 'brkts-matchlist-slot-bold bg-draw' or nil)
		:node(contentNode)
end

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component. Custom implementations should ensure that the rendered width is
exactly props.width.
]]
function MatchlistDisplay.Score(props)
	local contentNode = html.create('div'):addClass('brkts-matchlist-score')
		:node(OpponentDisplay.InlineScore(props.opponent))
		:css('width', (props.width - (2 * MatchlistDisplay.cellPadding) - 1) .. 'px')
	return html.create('td')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return Class.export(MatchlistDisplay)
