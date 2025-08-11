---
-- @Liquipedia
-- page=Module:MatchGroup/Display/Matchlist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local MatchlistDisplay = {propTypes = {}, types = {}}

local SCORE_DRAW = 0

---@class MatchlistConfigOptions
---@field MatchSummaryContainer function?
---@field Opponent function?
---@field Score function?
---@field attached boolean?
---@field collapsed boolean?
---@field matchHasDetails function?
---@field width number?

---@class MatchlistDisplayMatchProps
---@field MatchSummaryContainer function
---@field Opponent function
---@field Score function
---@field match MatchGroupUtilMatch
---@field matchHasDetails function

---@param args table
---@return table
function MatchlistDisplay.configFromArgs(args)
	return {
		attached = Logic.readBoolOrNil(args.attached),
		collapsed = Logic.readBoolOrNil(args.collapsed),
		width = tonumber((string.gsub(args.width or '', 'px', ''))),
	}
end

---Display component for a tournament matchlist. The matchlist is specified by ID.
---The component fetches the match data from LPDB or page variables.
---@param props {bracketId: string, config: MatchlistConfigOptions}
---@param matches MatchGroupUtilMatch[]
---@return Widget
function MatchlistDisplay.MatchlistContainer(props, matches)
	return MatchlistDisplay.Matchlist({
		config = props.config,
		matches = matches or MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

---Display component for a tournament matchlist. Match data is specified in the input.
---@param props {config: MatchlistConfigOptions, matches: MatchGroupUtilMatch[]}
---@return Widget
function MatchlistDisplay.Matchlist(props)
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		Opponent = propsConfig.Opponent or MatchlistDisplay.Opponent,
		Score = propsConfig.Score or MatchlistDisplay.Score,
		attached = propsConfig.attached or false,
		collapsed = propsConfig.collapsed or false,
		matchHasDetails = propsConfig.matchHasDetails or WikiSpecific.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
		width = propsConfig.width or 300,
	}

	return GeneralCollapsible{
		title = props.matches[1] and props.matches[1].bracketData.title or 'Match List',
		titleClasses = {'brkts-matchlist-title'},
		classes = {'brkts-matchlist', config.attached and 'brkts-matchlist-attached' or nil},
		collapseAreaClasses = {'brkts-matchlist-collapse-area'},
		attributes = {style = 'width: ' .. config.width .. 'px;'},
		shouldCollapse = config.collapsed,
		children = Array.flatMap(props.matches, function(match)
			local headerNode = match.bracketData.header
				and MatchlistDisplay.Header({
				header = match.bracketData.header,
				})
				or nil

			local dateHeaderNode = match.bracketData.dateHeader
				and match.dateIsExact
				and MatchlistDisplay.DateHeader({match = match})
				or nil

			local matchNode = MatchlistDisplay.Match({
				MatchSummaryContainer = config.MatchSummaryContainer,
				Opponent = config.Opponent,
				Score = config.Score,
				match = match,
				matchHasDetails = config.matchHasDetails,
			})

			return WidgetUtil.collect(headerNode, dateHeaderNode, matchNode)
		end)
	}
end

---Display component for a match in a matchlist. Consists of two opponents, two scores,
---and a icon for the match summary popup.
---@param props MatchlistDisplayMatchProps
---@return Html
function MatchlistDisplay.Match(props)
	local match = props.match

	local function renderOpponent(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local opponentNode = props.Opponent({
			opponent = opponent,
			winner = match.winner,
			side = opponentIx == 1 and 'left' or 'right',
		})
		return DisplayHelper.addOpponentHighlight(opponentNode, opponent)
	end

	local function renderScore(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local scoreNode = props.Score({
			opponent = opponent,
			side = opponentIx == 1 and 'left' or 'right',
		})
		return DisplayHelper.addOpponentHighlight(scoreNode, opponent)
	end

	local matchInfoIconNode
	local matchSummaryNode
	if props.matchHasDetails(match) then
		matchInfoIconNode = mw.html.create('div'):addClass('brkts-match-info-icon')
		local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
		matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
			bracketId = bracketId,
			matchId = props.match.matchId,
		}, Lua.import('Module:Error/Display').ErrorDetails)
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

---Display component for a header in a matchlist.
---@param props {header: string}
---@return Html
function MatchlistDisplay.Header(props)
	local headerNode = mw.html.create('div'):addClass('brkts-matchlist-header')
		:wikitext(props.header)

	return DisplayUtil.applyOverflowStyles(headerNode, 'wrap')
end

---Display component for a dateHeader in a matchlist.
---@param props {match: MatchGroupUtilMatch}
---@return Html
function MatchlistDisplay.DateHeader(props)
	local dateHeaderNode = mw.html.create('div'):addClass('brkts-matchlist-header')
		:node(DisplayHelper.MatchCountdownBlock(props.match))

	return DisplayUtil.applyOverflowStyles(dateHeaderNode, 'wrap')
end

--[[
Display component for an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Opponent to the Matchlist
component.
]]
---@param props {opponent: standardOpponent, winner: integer?, side: string}
---@return Html
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
		:addClass(props.winner == SCORE_DRAW and 'brkts-matchlist-slot-bold bg-draw' or
			props.opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil)
		:node(contentNode)
end

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component.
]]
---@param props {opponent: standardOpponent, side: string}
---@return Html
function MatchlistDisplay.Score(props)
	local contentNode = mw.html.create('div'):addClass('brkts-matchlist-cell-content')
		:node(OpponentDisplay.InlineScore(props.opponent))
	return mw.html.create('div')
		:addClass('brkts-matchlist-cell brkts-matchlist-score')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return MatchlistDisplay
