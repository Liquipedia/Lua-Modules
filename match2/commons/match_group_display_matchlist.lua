local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local html = mw.html

local MatchlistDisplay = {propTypes = {}, types = {}}

-- Called by MatchGroup/Display
function MatchlistDisplay.luaGet(_, args)
	return MatchlistDisplay.MatchlistContainer({
		bracketId = args[1],
		config = MatchlistDisplay.configFromArgs(args),
	})
end

MatchlistDisplay.configFromArgs = function(args)
	return {
		attached = Logic.readBool(args.attached),
		collapsed = Logic.readBool(args.collapsed),
		collapsible = not Logic.readBool(args.nocollapse),
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
		collapsible = Logic.emptyOr(propsConfig.collapsible, true),
		matchHasDetails = propsConfig.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
		width = propsConfig.width or 300,
	}
	local tableNode = html.create('table')
		:addClass('brkts-matchlist wikitable wikitable-bordered matchlist')
		:addClass(config.collapsible and 'collapsible' or nil)
		:addClass(config.collapsed and 'collapsed' or nil)
		:cssText(config.attached and 'margin-bottom:-1px;margin-top:-2px' or nil)
		:css('width', config.width .. 'px')

	for index, match in ipairs(props.matches) do
		local titleNode = index == 1
			and MatchlistDisplay.Title({title = match.bracketData.title or 'Match List'})
			or nil

		local headerNode = match.bracketData.header
			and MatchlistDisplay.Header({header = match.bracketData.header})
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

	local padding = 5
	local opponentWidth = math.floor(0.4 * props.width) - 1
	local scoreWidth = 0.5 * (props.width - 5 - 2 * opponentWidth)

	local renderOpponent = function(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local opponentNode = props.Opponent({
			opponent = opponent,
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
			width = opponentWidth,
		})
			:css('width', opponentWidth - 2 * padding .. 'px')
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
			:css('width', scoreWidth - 2 * padding .. 'px')
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
		:addClass('brtks-matchlist-row brkts-match-popup-wrapper')
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
	local thNode = html.create('th')
		:addClass('brkts-matchlist-title')
		:attr('colspan', '5')
		:node(
			html.create('center')
				:wikitext(props.title)
		)
	return html.create('tr')
		:node(thNode)
end

MatchlistDisplay.propTypes.Header = {
	header = 'string',
}

--[[
Display component for a header in a matchlist.
]]
function MatchlistDisplay.Header(props)
	DisplayUtil.assertPropTypes(props, MatchlistDisplay.propTypes.Header)

	local thNode = html.create('th')
		:addClass('brkts-matchlist-header')
		:attr('colspan', '5')
		:node(
			html.create('center')
				:wikitext(props.header)
		)
	return html.create('tr')
		:node(thNode)
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
		:css('width', props.width - 2 * padding .. 'px')
	return html.create('td')
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
	local contentNode = html.create('div'):addClass('brkts-matchlist-score')
		:node(OpponentDisplay.InlineScore(props.opponent))
		:css('width', props.width - 2 * padding .. 'px')
	return html.create('td')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return Class.export(MatchlistDisplay)
