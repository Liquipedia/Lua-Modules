---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Matchlist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local MatchlistDisplay = {propTypes = {}, types = {}}

---@class MatchlistConfigOptions
---@field MatchSummaryContainer function?
---@field Opponent function?
---@field Score function?
---@field attached boolean?
---@field collapsed boolean?
---@field collapsible boolean?
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
		collapsible = not Logic.readBoolOrNil(args.nocollapse),
		width = tonumber((string.gsub(args.width or '', 'px', ''))),
	}
end

---Display component for a tournament matchlist. The matchlist is specified by ID.
---The component fetches the match data from LPDB or page variables.
---@param props {bracketId: string, config: MatchlistConfigOptions}
---@param matches MatchGroupUtilMatch[]
---@return Html
function MatchlistDisplay.MatchlistContainer(props, matches)
	return MatchlistDisplay.Matchlist({
		config = props.config,
		matches = matches or MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

---Display component for a tournament matchlist. Match data is specified in the input.
---@param props {config: MatchlistConfigOptions, matches: MatchGroupUtilMatch[]}
---@return Html
function MatchlistDisplay.Matchlist(props)
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		Opponent = propsConfig.Opponent or MatchlistDisplay.Opponent,
		Score = propsConfig.Score or MatchlistDisplay.Score,
		attached = propsConfig.attached or false,
		collapsed = propsConfig.collapsed or false,
		collapsible = Logic.nilOr(propsConfig.collapsible, true),
		matchHasDetails = propsConfig.matchHasDetails or WikiSpecific.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
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

		matchlistNode:node(titleNode):node(headerNode):node(dateHeaderNode):node(matchNode)
	end

	return matchlistNode
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
			resultType = match.resultType,
			side = opponentIx == 1 and 'left' or 'right',
		})
		return DisplayHelper.addOpponentHighlight(opponentNode, opponent)
	end

	local function renderScore(opponentIx)
		local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

		local scoreNode = props.Score({
			opponent = opponent,
			resultType = match.resultType,
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
		}, require('Module:Error/Display').ErrorDetails)
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

---Display component for a title in a matchlist.
---@param props {title: string}
---@return Html
function MatchlistDisplay.Title(props)
	local titleNode = mw.html.create('div'):addClass('brkts-matchlist-title')
		:wikitext(props.title)

	return DisplayUtil.applyOverflowStyles(titleNode, 'wrap')
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
---@param props {opponent: standardOpponent, resultType: ResultType, side: string}
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
		:addClass(props.resultType == 'draw' and 'brkts-matchlist-slot-bold bg-draw' or
			props.opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil)
		:node(contentNode)
end

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component.
]]
---@param props {opponent: standardOpponent, resultType: ResultType, side: string}
---@return Html
function MatchlistDisplay.Score(props)
	local contentNode = mw.html.create('div'):addClass('brkts-matchlist-cell-content')
		:node(OpponentDisplay.InlineScore(props.opponent))
	return mw.html.create('div')
		:addClass('brkts-matchlist-cell brkts-matchlist-score')
		:addClass(props.opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil)
		:node(contentNode)
end

return Class.export(MatchlistDisplay)
