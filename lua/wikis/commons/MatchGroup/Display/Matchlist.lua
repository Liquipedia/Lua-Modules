---
-- @Liquipedia
-- page=Module:MatchGroup/Display/Matchlist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local MatchInfoIcon = Lua.import('Module:Widget/Match/InfoIcon')
local MatchListHeader = Lua.import('Module:Widget/Match/List/Header')
local MatchlistOpponent = Lua.import('Module:Widget/Match/List/Opponent')
local MatchlistScore = Lua.import('Module:Widget/Match/List/Score')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MatchlistDisplay = {propTypes = {}, types = {}}

---@class MatchlistConfigOptions
---@field MatchSummaryContainer function?
---@field Opponent Component<{opponent: standardOpponent, winner: integer?, side: 'left'|'right'}>?
---@field Score Component<{opponent: standardOpponent, side: 'left'|'right'}>?
---@field attached boolean?
---@field collapsed boolean?
---@field matchHasDetails function?
---@field width number?

---@class MatchlistDisplayMatchProps
---@field MatchSummaryContainer function
---@field Opponent Component<{opponent: standardOpponent, winner: integer?, side: 'left'|'right'}>
---@field Score Component<{opponent: standardOpponent, side: 'left'|'right'}>
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
---@return VNode
function MatchlistDisplay.MatchlistContainer(props, matches)
	return MatchlistDisplay.Matchlist{
		config = props.config,
		matches = matches or MatchGroupUtil.fetchMatches(props.bracketId),
	}
end

---Display component for a tournament matchlist. Match data is specified in the input.
---@param props {config: MatchlistConfigOptions, matches: MatchGroupUtilMatch[]}
---@return VNode
function MatchlistDisplay.Matchlist(props)
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		Opponent = propsConfig.Opponent or MatchlistOpponent,
		Score = propsConfig.Score or MatchlistScore,
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
			local headerNode = MatchlistDisplay.Header(match.bracketData.header)
			local dateHeaderNode = MatchlistDisplay.DateHeader(match)

			local matchNode = MatchlistDisplay.Match{
				MatchSummaryContainer = config.MatchSummaryContainer,
				Opponent = config.Opponent,
				Score = config.Score,
				match = match,
				matchHasDetails = config.matchHasDetails,
			}

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

	---@param opponentIx integer
	---@return VNode
	local function renderOpponent(opponentIx)
		local opponent = match.opponents[opponentIx] or Opponent.blank(Opponent.literal)

		return props.Opponent{
			opponent = opponent,
			winner = match.winner,
			side = opponentIx == 1 and 'left' or 'right',
		}
	end

	---@param opponentIx integer
	---@return VNode
	local function renderScore(opponentIx)
		local opponent = match.opponents[opponentIx] or Opponent.blank(Opponent.literal)

		return props.Score{
			opponent = opponent,
			side = opponentIx == 1 and 'left' or 'right',
		}
	end

	local matchInfoIconNode
	local matchSummaryNode
	if props.matchHasDetails(match) then
		matchInfoIconNode = MatchInfoIcon{}
		local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
		matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
			classes = {'brkts-match-info-popup'},
			bracketId = bracketId,
			matchId = props.match.matchId,
		}, Lua.import('Module:Error/Display').ErrorDetails)
	else
		matchInfoIconNode = Html.Div{
			classes = {'brkts-matchlist-placeholder-cell'}
		}
	end

	return Html.Div{
		classes = Array.extend(
			'brkts-matchlist-match',
			matchSummaryNode and 'brkts-match-has-details brkts-match-popup-wrapper' or nil
		),
		children = WidgetUtil.collect(
			renderOpponent(1),
			renderScore(1),
			matchInfoIconNode,
			renderScore(2),
			renderOpponent(2),
			matchSummaryNode
		)
	}
end

---Display component for a header in a matchlist.
---@param header string?
---@return VNode?
function MatchlistDisplay.Header(header)
	if not header then
		return
	end
	return MatchListHeader{
		children = header
	}
end

---Display component for a dateHeader in a matchlist.
---@param match MatchGroupUtilMatch
---@return VNode?
function MatchlistDisplay.DateHeader(match)
	if not match.bracketData.dateHeader or not match.dateIsExact then
		return
	end
	return MatchListHeader{
		children = Html.Div{
			css = {padding = '2px 10px'},
			children = Countdown.create(Table.merge(match.stream, {
				date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact),
				finished = match.finished,
				rawdatetime = (not match.dateIsExact) or match.finished,
			}))
		}
	}
end

return MatchlistDisplay
