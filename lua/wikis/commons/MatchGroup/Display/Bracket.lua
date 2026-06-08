---
-- @Liquipedia
-- page=Module:MatchGroup/Display/Bracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local StringUtils = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local Opponent = Lua.import('Module:Opponent/Custom')

local BracketLineNode = Lua.import('Module:Widget/Match/Bracket/LineNode')
local BracketNodeConnector = Lua.import('Module:Widget/Match/Bracket/NodeConnector')
local Html = Lua.import('Module:Widget/Html')
local BracketOpponentEntry = Lua.import('Module:Widget/Match/Bracket/OpponentEntry')
local MatchHeader = Lua.import('Module:Widget/Match/Bracket/MatchHeader')
local MatchInfoIcon = Lua.import('Module:Widget/Match/InfoIcon')

local OPPONENT_HEIGHT_PADDING = 4

---@class BracketConfigOptions
---@field MatchSummaryContainer? fun(props: table): Renderable
---@field OpponentEntry Component<BracketOpponentEntryProps>?
---@field forceShortName boolean?
---@field headerHeight number?
---@field headerMargin number?
---@field hideRoundTitles boolean?
---@field lineWidth number?
---@field matchHasDetails function?
---@field matchMargin number?
---@field matchWidth number?
---@field matchWidthMobile number?
---@field opponentHeight number?
---@field qualifiedHeader string?
---@field roundHorizontalMargin number?
---@field scoreWidth number?

---@class BracketDisplayLayout
---@field height number
---@field lowerNodeMarginTop number
---@field matchHeight number
---@field matchMarginTop number
---@field mid number

---@class BracketDisplayNodeHeaderProps
---@field config BracketConfigOptions
---@field layoutsByMatchId table<string, BracketDisplayLayout>
---@field matchId string
---@field matchesById table<string, MatchGroupUtilMatch>
---@field headerRowsByMatchId table<string, table[]>

---@class BracketDisplayNodeBodyProps
---@field config BracketConfigOptions
---@field layoutsByMatchId table<string, BracketDisplayLayout>
---@field matchId string
---@field matchesById table<string, MatchGroupUtilMatch>

---@class BracketDisplayMatchProps
---@field OpponentEntry Component<BracketOpponentEntryProps>
---@field MatchSummaryContainer? fun(props: table): Renderable
---@field match MatchGroupUtilMatch
---@field forceShortName boolean
---@field matchHasDetails function
---@field opponentHeight number

local BracketDisplay = {propTypes = {}, types = {}}

---@param args table
---@return BracketConfigOptions
function BracketDisplay.configFromArgs(args)
	return {
		forceShortName = Logic.readBoolOrNil(args.forceShortName),
		headerHeight = tonumber(args.headerHeight),
		headerMargin = tonumber(args.headerMargin),
		hideRoundTitles = Logic.readBoolOrNil(args.hideRoundTitles),
		lineWidth = tonumber(args.lineWidth),
		matchMargin = tonumber(args.matchMargin),
		matchWidth = tonumber(args.matchWidth),
		matchWidthMobile = tonumber(args.matchWidthMobile),
		opponentHeight = tonumber(args.opponentHeight),
		qualifiedHeader = args.qualifiedHeader,
		roundHorizontalMargin = tonumber(args.roundHorizontalMargin),
		scoreWidth = tonumber(args.scoreWidth),
	}
end

---Display component for a tournament bracket. The bracket is specified by ID.
---The component fetches the match data from LPDB or page variables.
---@param props {bracketId: string, config: BracketConfigOptions}
---@return VNode
function BracketDisplay.BracketContainer(props)
	return BracketDisplay.Bracket{
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId) --[[@as MatchGroupUtilBracket]],
		config = props.config,
	}
end

---Display component for a tournament bracket. Match data is specified in the input.
---@param props {bracket: MatchGroupUtilBracket, config: BracketConfigOptions}
---@return VNode
function BracketDisplay.Bracket(props)
	local defaultConfig = DisplayHelper.getGlobalConfig()
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		OpponentEntry = propsConfig.OpponentEntry or BracketOpponentEntry,
		forceShortName = propsConfig.forceShortName or defaultConfig.forceShortName,
		headerHeight = propsConfig.headerHeight or defaultConfig.headerHeight,
		headerMargin = propsConfig.headerMargin or defaultConfig.headerMargin,
		hideRoundTitles = propsConfig.hideRoundTitles or false,
		lineWidth = propsConfig.lineWidth or defaultConfig.lineWidth,
		matchHasDetails = propsConfig.matchHasDetails or WikiSpecific.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
		matchMargin = propsConfig.matchMargin or math.floor(defaultConfig.opponentHeight / 4),
		matchWidth = propsConfig.matchWidth or defaultConfig.matchWidth,
		matchWidthMobile = propsConfig.matchWidthMobile or defaultConfig.matchWidthMobile,
		opponentHeight = propsConfig.opponentHeight
			or BracketDisplay.computeBracketOpponentHeight(props.bracket.matchesById, defaultConfig.opponentHeight),
		qualifiedHeader = propsConfig.qualifiedHeader or defaultConfig.qualifiedHeader,
		roundHorizontalMargin = propsConfig.roundHorizontalMargin or defaultConfig.roundHorizontalMargin,
		scoreWidth = propsConfig.scoreWidth or defaultConfig.scoreWidth,
	}

	local headerRowsByMatchId = BracketDisplay.computeHeaderRows(props.bracket, config)
	local layoutsByMatchId = BracketDisplay.computeBracketLayout(props.bracket, config, headerRowsByMatchId)

	return Html.Div{
		classes = {'brkts-bracket-wrapper'},
		children = Html.Div{
			classes = {'brkts-bracket'},
			css = {
				['--match-width'] = config.matchWidth .. 'px',
				['--match-width-mobile'] = config.matchWidthMobile .. 'px',
				['--score-width'] = config.scoreWidth .. 'px',
				['--round-horizontal-margin'] = config.roundHorizontalMargin .. 'px',
				['--opponent-height'] = config.opponentHeight .. 'px',
			},
			children = Array.flatMap(props.bracket.rootMatchIds, function (matchId)
				-- Draw all top level subtrees of the bracket. These are subtrees rooted
				-- at matches that do not advance to higher rounds.
				if StringUtils.endsWith(matchId, 'RxMTP') then
					return
				end
				local nodeProps = {
					config = config,
					headerRowsByMatchId = headerRowsByMatchId,
					layoutsByMatchId = layoutsByMatchId,
					matchId = matchId,
					matchesById = props.bracket.matchesById,
				}
				return {
					BracketDisplay.NodeHeader(nodeProps),
					BracketDisplay.NodeBody(nodeProps),
				}
			end)
		}
	}
end

---@param matchesById table<string, MatchGroupUtilMatch>
---@param defaultOpponentHeight integer
---@return number
function BracketDisplay.computeBracketOpponentHeight(matchesById, defaultOpponentHeight)
	local maxHeight = defaultOpponentHeight

	for _, match in pairs(matchesById) do
		for _, opponent in ipairs(match.opponents) do
			maxHeight = math.max(maxHeight, BracketDisplay._computeOpponentHeight(opponent.type, defaultOpponentHeight))
		end
	end

	return maxHeight
end

---@param opponentType OpponentType
---@param defaultOpponentHeight integer
---@return number
function BracketDisplay._computeOpponentHeight(opponentType, defaultOpponentHeight)
	local numberOfRows = Opponent.partySize(opponentType) or 1

	-- remove padding then multipy it by player rows and after that add padding once
	return numberOfRows * (defaultOpponentHeight - OPPONENT_HEIGHT_PADDING) + OPPONENT_HEIGHT_PADDING
end

---Computes certain layout properties of nodes in the bracket tree.
---@param bracket MatchGroupUtilBracket
---@param config BracketConfigOptions
---@param headerRowsByMatchId table<string, table[]>
---@return table<string, BracketDisplayLayout>
function BracketDisplay.computeBracketLayout(bracket, config, headerRowsByMatchId)
	-- Computes the layout of a match and everything to its left.
	---@param matchId string
	---@param computeNodeLayout function
	---@return BracketDisplayLayout
	local computeNodeLayout = FnUtil.memoizeY(function(matchId, computeNodeLayout)
		local match = bracket.matchesById[matchId]

		-- Recurse on lower round matches
		local lowerLayouts = Array.map(match.bracketData.lowerMatchIds, computeNodeLayout)

		-- Compute partial sums of heights of lower round matches
		local heightSums = MathUtil.partialSums(
			Array.map(lowerLayouts, function(layout) return layout.height end)
		)

		local headerFullHeight = headerRowsByMatchId[matchId]
			and config.headerMargin + config.headerHeight + math.max(config.headerMargin - config.matchMargin, 0)
			or 0
		local matchHeight = #match.opponents * config.opponentHeight

		-- Compute offset with lower nodes
		local matchTop = BracketDisplay.alignMatchWithLowerNodes(match, lowerLayouts, heightSums, config.opponentHeight)
		-- Vertical space between lower rounds and top of bracket node body
		local lowerNodeMarginTop = matchTop < 0 and -matchTop or 0
		-- Vertical space between match and top of bracket node body
		local matchMarginTop = 0 < matchTop and matchTop or 0

		-- Ensure matchMarginTop is at least config.matchMargin
		if matchMarginTop < config.matchMargin then
			lowerNodeMarginTop = lowerNodeMarginTop + config.matchMargin - matchMarginTop
			matchMarginTop = config.matchMargin
		end

		-- Distance between middle of match and top of the bracket node header
		local mid = headerFullHeight + matchMarginTop + matchHeight / 2

		-- Height of this node, including the header but excluding the 3rd
		-- place match and qualifier rounds.
		local height = headerFullHeight
			+ math.max(
				lowerNodeMarginTop + heightSums[#heightSums],
				matchMarginTop + matchHeight + config.matchMargin
			)

		return {
			height = height,
			lowerNodeMarginTop = lowerNodeMarginTop,
			matchHeight = matchHeight,
			matchMarginTop = matchMarginTop,
			mid = mid,
		}
	end)

	return Table.mapValues(bracket.matchesById, function(match)
		return computeNodeLayout(match.matchId) --[[@as BracketDisplayLayout]]
	end)
end

-- Computes the vertical offset of a match with its lower round matches
---@param match MatchGroupUtilMatch
---@param lowerLayouts BracketDisplayLayout
---@param heightSums number[]
---@param opponentHeight number
---@return number
function BracketDisplay.alignMatchWithLowerNodes(match, lowerLayouts, heightSums, opponentHeight)
	local matchHeight = #match.opponents * opponentHeight

	-- Show a connector line without joints if there is a single lower round
	-- match advancing an opponent that is placed near the middle of this match.
	local showSingleStraightLine = false
	if #lowerLayouts == 1 then
		local opponentIx = match.bracketData.lowerEdges[1].opponentIndex
		if #match.opponents % 2 == 0 then
			showSingleStraightLine = opponentIx == #match.opponents / 2
				or opponentIx == #match.opponents / 2 + 1
		else
			showSingleStraightLine = opponentIx == math.floor(#match.opponents / 2) + 1
		end
	end

	-- Align the match with its lower round matches
	if showSingleStraightLine then
		-- Single straight line: Align the connecting line with the middle
		-- of the opponent it connects into.
		local opponentIx = match.bracketData.lowerEdges[1].opponentIndex
		return lowerLayouts[1].mid
			- ((opponentIx - 1) + 0.5) * opponentHeight

	elseif 0 < #lowerLayouts then
		if #lowerLayouts % 2 == 0 then
			-- Even number of lower round matches: Align this match to the
			-- midpoint of the middle two lower round matches.
			local aMid = heightSums[#lowerLayouts / 2] + lowerLayouts[#lowerLayouts / 2].mid
			local bMid = heightSums[#lowerLayouts / 2 + 1] + lowerLayouts[#lowerLayouts / 2 + 1].mid
			return (aMid + bMid) / 2 - matchHeight / 2

		else
			-- Odd number of lower round matches: Align this match to the
			-- middle one.
			local middleLowerLayout = lowerLayouts[math.floor(#lowerLayouts / 2) + 1]
			return heightSums[math.floor(#lowerLayouts / 2) + 1] + middleLowerLayout.mid
				- matchHeight / 2
		end
	else
		-- No lower matches
		return 0
	end
end

---@param bracket MatchGroupUtilBracket
---@param config BracketConfigOptions
---@return table<string, table[]>
function BracketDisplay.computeHeaderRows(bracket, config)
	if config.hideRoundTitles then
		return {}
	end

	-- Compute which matches have header rows
	local headerRows = {}
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		-- Don't show the header if it's disabled. Also don't show the header
		-- if it is the first match of a round because a higher round match can
		-- show it instead.
		local upperBracketData = bracketData.upperMatchId
			and bracket.bracketDatasById[bracketData.upperMatchId]
		local isFirstChild = upperBracketData
			and matchId == upperBracketData.lowerMatchIds[1]
		local showHeader = bracketData.header and not isFirstChild
		if showHeader then
			headerRows[matchId] = {}
		end
	end

	-- Starting from a match, walks up the bracket tree to higher round
	-- matches. When it gets to a root, it then traverses the roots in
	-- reverse order until it gets to the first root.
	local function getParent(matchId)
		local bracketData = bracket.bracketDatasById[matchId]
		local coords = bracket.coordinatesByMatchId[matchId]
		return bracketData.upperMatchId
			or coords.rootIndex ~= 1 and bracket.rootMatchIds[coords.rootIndex - 1]
			or nil
	end

	-- Finds a match's closest ancestor that has a header row
	local getHeaderRow = FnUtil.memoizeY(function(matchId, getHeaderRow)
		return headerRows[matchId] or getHeaderRow(getParent(matchId))
	end)

	-- Determine the individual headers appearing in header rows
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		local coords = bracket.coordinatesByMatchId[matchId]
		if bracketData.header then
			local headerRow = getHeaderRow(matchId)
			local brMatch = bracketData.bracketResetMatchId and bracket.matchesById[bracketData.bracketResetMatchId]
			headerRow[coords.roundIndex] = {
				hasBrMatch = brMatch and true or false,
				header = bracketData.header,
				roundIx = coords.roundIndex,
			}
		end
		if bracketData.qualWin then
			local headerRow = getHeaderRow(matchId)
			local roundIx = coords.roundIndex + 1 + bracketData.qualSkip
			headerRow[roundIx] = headerRow[roundIx] or {
				header = config.qualifiedHeader or '!q',
				roundIx = roundIx,
			}
			headerRow[roundIx].header = bracketData.qualifiedHeader or headerRow[roundIx].header
		end
	end

	-- Convert each header row from a table to a sorted array
	return Table.mapValues(headerRows, function(headerRow)
		local headerRowArray = {}
		for _, cell in pairs(headerRow) do
			table.insert(headerRowArray, cell)
		end
		table.sort(headerRowArray, function(a, b) return a.roundIx < b.roundIx end)
		return headerRowArray
	end)
end

---Display component for the headers of a node in the bracket tree. Draws a row of headers for the match,
---everything to the left of it, and for the qualification spots.
---@param props BracketDisplayNodeHeaderProps
---@return Html?
function BracketDisplay.NodeHeader(props)
	local headerRow = props.headerRowsByMatchId[props.matchId]
	local config = props.config
	if not headerRow then
		return nil
	end

	local headerNode = mw.html.create('div'):addClass('brkts-round-header')
		:css('--header-margin', config.headerMargin .. 'px')
		:css('--match-margin', config.matchMargin .. 'px')

	local cursorRoundIx = 1
	for _, cell in ipairs(headerRow) do
		headerNode:node(
			MatchHeader{
				header = cell.header,
				height = config.headerHeight,
				additionalClasses = cell.hasBrMatch and {'brkts-br-wrapper'} or nil,
				css = {['--skip-round'] = cell.roundIx - cursorRoundIx}
			}
		)
		cursorRoundIx = cell.roundIx + 1
	end

	return headerNode
end

---Display component for a node in the bracket tree, which consists of a match and all the lower round matches leading
---up to it. Also includes qualification spots and line connectors between lower round matches, the current match, and
---qualification spots.
---@param props BracketDisplayNodeBodyProps
---@return Html
function BracketDisplay.NodeBody(props)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config

	-- Matches from lower rounds
	local lowerNode
	if 0 < #match.bracketData.lowerMatchIds then
		lowerNode = mw.html.create('div'):addClass('brkts-round-lower')
			:css('margin-top', layout.lowerNodeMarginTop .. 'px')
		for _, lowerMatchId in ipairs(match.bracketData.lowerMatchIds) do
			local childProps = Table.merge(props, {matchId = lowerMatchId})
			lowerNode
				:node(BracketDisplay.NodeHeader(childProps))
				:node(BracketDisplay.NodeBody(childProps))
		end
	end

	-- Include results from bracketResetMatch
	---@type MatchGroupUtilMatch?
	local bracketResetMatch = match.bracketData.bracketResetMatchId
		and props.matchesById[match.bracketData.bracketResetMatchId]
	if bracketResetMatch then
		match = Logic.wrapTryOrLog(MatchGroupUtil.mergeBracketResetMatch)(match, bracketResetMatch)
	end

	-- Current match
	local matchNode = BracketDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		OpponentEntry = config.OpponentEntry,
		match = match,
		forceShortName = config.forceShortName,
		matchHasDetails = config.matchHasDetails,
		opponentHeight = config.opponentHeight,
	}
		:css('margin-top', layout.matchMarginTop .. 'px')
		:css('margin-bottom', config.matchMargin .. 'px')

	-- Third place match
	local thirdPlaceMatch = match.bracketData.thirdPlaceMatchId
		and props.matchesById[match.bracketData.thirdPlaceMatchId]
	local thirdPlaceHeaderNode
	local thirdPlaceMatchNode
	if thirdPlaceMatch then
		thirdPlaceHeaderNode = MatchHeader{
			header = thirdPlaceMatch.bracketData.header or '!tp',
			height = config.headerHeight,
			additionalClasses = {'brkts-third-place-header'},
			css = {
				['margin-top'] = 20 + config.headerMargin .. 'px',
				['margin-bottom'] = config.headerMargin .. 'px',
			},
		}
		thirdPlaceMatchNode = BracketDisplay.Match{
			MatchSummaryContainer = config.MatchSummaryContainer,
			OpponentEntry = config.OpponentEntry,
			match = thirdPlaceMatch,
			forceShortName = config.forceShortName,
			matchHasDetails = config.matchHasDetails,
			opponentHeight = config.opponentHeight,
		}
			:addClass('brkts-third-place-match')
	end

	local centerNode = mw.html.create('div'):addClass('brkts-round-center')
		:addClass(bracketResetMatch and 'brkts-br-wrapper' or nil)
		:node(matchNode)
		:node(thirdPlaceHeaderNode)
		:node(thirdPlaceMatchNode)

	-- Qualifier entries
	local qualWinNode
	if match.bracketData.qualWin then
		local winner = (bracketResetMatch or match).winner
		local opponent = winner
			and match.opponents[winner]
			or MatchGroupUtil.createOpponent{
				type = 'literal',
				name = match.bracketData.qualWinLiteral or '',
			}
		qualWinNode = BracketDisplay.Qualified{
			OpponentEntry = config.OpponentEntry,
			height = config.opponentHeight,
			opponent = opponent,
		}
			:css('margin-top', layout.matchMarginTop + layout.matchHeight / 2 - config.opponentHeight / 2 .. 'px')
			:css('margin-bottom', config.matchMargin .. 'px')
	end

	local qualLoseNode
	if match.bracketData.qualLose then
		local opponent = BracketDisplay.getRunnerUpOpponent(match, bracketResetMatch)
			or MatchGroupUtil.createOpponent({
				type = 'literal',
				name = match.bracketData.qualLoseLiteral or '',
			})
		qualLoseNode = BracketDisplay.Qualified{
			OpponentEntry = config.OpponentEntry,
			height = config.opponentHeight,
			opponent = opponent,
		}
			:css('margin-top', config.matchMargin + 6 .. 'px')
			:css('margin-bottom', config.matchMargin .. 'px')
	end

	local qualNode
	if qualWinNode or qualLoseNode then
		qualNode = mw.html.create('div'):addClass('brkts-round-qual')
			:node(qualWinNode)
			:node(qualLoseNode)
	end

	return mw.html.create('div'):addClass('brkts-round-body')
		:css('--skip-round', match.bracketData.skipRound)
		:css('--qual-skip', match.bracketData.qualSkip)
		:node(lowerNode)
		:node(lowerNode and BracketDisplay.NodeLowerConnectors(props) or nil)
		:node(centerNode)
		:node(qualNode and BracketDisplay.NodeQualConnectors(props) or nil)
		:node(qualNode)
end

---Display component for a match in a bracket. Draws one row for each opponent, and an icon for the match summary popup.
---@param props BracketDisplayMatchProps
---@return Html
function BracketDisplay.Match(props)
	local matchNode = mw.html.create('div'):addClass('brkts-match brkts-match-popup-wrapper')

	for ix, opponent in ipairs(props.match.opponents) do
		local opponentEntryNode = props.OpponentEntry{
			displayType = 'bracket',
			forceShortName = props.forceShortName,
			height = props.opponentHeight,
			opponent = opponent,
			classes = ix == #props.match.opponents and {'brkts-opponent-entry-last'} or nil,
		}
		matchNode:node(opponentEntryNode)
	end

	if props.matchHasDetails(props.match) then
		local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
		local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
			classes = {'brkts-match-info-popup'},
			bracketId = bracketId,
			matchId = props.match.matchId,
		}, Lua.import('Module:Error/Display').ErrorDetails)

		local matchInfoIconNode = MatchInfoIcon{
			css = {
				-- Vertically align the middle of the match with the middle
				-- of the 12px icon. The -1 is for the top border of the match.
				top = #props.match.opponents * props.opponentHeight / 2 - 12 / 2 - 1 .. 'px'
			}
		}

		matchNode
			:node(matchInfoIconNode):node(matchSummaryNode)
			:addClass('brkts-match-has-details brkts-match-popup-wrapper')
	end

	return matchNode
end

---Display component for a qualification spot.
---@param props {OpponentEntry: Component<BracketOpponentEntryProps>, height: number, opponent: standardOpponent}
---@return Html
function BracketDisplay.Qualified(props)
	local opponentEntryNode = props.OpponentEntry{
		displayType = 'bracket-qualified',
		height = props.height,
		opponent = props.opponent,
		classes = {'brkts-opponent-entry-last'},
	}

	return mw.html.create('div'):addClass('brkts-qualified')
		:node(opponentEntryNode)
end

---@param props BracketDisplayNodeBodyProps
---@return Html
function BracketDisplay.NodeLowerConnectors(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeLowerConnectors)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config
	local bracketData = match.bracketData

	local lowerLayouts = Array.map(
		bracketData.lowerMatchIds,
		function(lowerMatchId) return props.layoutsByMatchId[lowerMatchId] end
	)

	-- Compute partial sums of heights of lower round matches
	local heightSums = MathUtil.partialSums(
		Array.map(lowerLayouts, function(l) return l.height end)
	)

	-- Compute joints of connectors
	local jointIxs = {}
	local jointIxAbove = 0
	for ix = math.ceil(#bracketData.lowerEdges / 2), 1, -1 do
		local lowerEdge = bracketData.lowerEdges[ix]
		if not jointIxs[lowerEdge.opponentIndex] then
			jointIxAbove = jointIxAbove + 1
			jointIxs[lowerEdge.opponentIndex] = jointIxAbove
		end
	end
	local jointIxBelow = 0
	-- middle lower match is repeated if odd
	for ix = math.floor(#bracketData.lowerEdges / 2) + 1, #bracketData.lowerEdges, 1 do
		local lowerEdge = bracketData.lowerEdges[ix]
		if not jointIxs[lowerEdge.opponentIndex] then
			jointIxBelow = jointIxBelow + 1
			jointIxs[lowerEdge.opponentIndex] = jointIxBelow
		end
	end
	local jointCount = math.max(jointIxAbove, jointIxBelow)

	local lowerConnectorsNode = mw.html.create('div'):addClass('brkts-round-lower-connectors')

	-- Draw connectors between lower round matches and this match
	for _, lowerEdge in ipairs(bracketData.lowerEdges) do
		local lowerLayout = lowerLayouts[lowerEdge.lowerMatchIndex]
		lowerConnectorsNode:node(
			BracketNodeConnector{
				jointLeft = (config.roundHorizontalMargin - 2) * jointIxs[lowerEdge.opponentIndex] / (jointCount + 1),
				leftTop = layout.lowerNodeMarginTop + heightSums[lowerEdge.lowerMatchIndex] + lowerLayout.mid,
				lineWidth = config.lineWidth,
				rightTop = layout.matchMarginTop + ((lowerEdge.opponentIndex - 1) + 0.5) * config.opponentHeight,
			}
		)
	end

	-- Draw line stubs for opponents not connected to a lower round match
	for opponentIx, _ in ipairs(match.opponents) do
		if not jointIxs[opponentIx] then
			lowerConnectorsNode:node(
				BracketDisplay.ConnectorStub{
					lineWidth = config.lineWidth,
					rightTop = layout.matchMarginTop + ((opponentIx - 1) + 0.5) * config.opponentHeight,
				}
			)
		end
	end

	return lowerConnectorsNode
end

-- Connector lines between a match and its qualified spots
---@param props BracketDisplayNodeBodyProps
---@return VNode
function BracketDisplay.NodeQualConnectors(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeQualConnectors)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config

	local leftTop = layout.matchMarginTop + layout.matchHeight / 2

	return Html.Div{
		classes = {'brkts-round-qual-connectors'},
		children = {
			-- Qualified winner connector
			BracketNodeConnector{
				leftTop = leftTop,
				lineWidth = config.lineWidth,
				rightTop = leftTop,
			},
			-- Qualified loser connector
			match.bracketData.qualLose and BracketNodeConnector{
				jointRight = 11,
				leftTop = leftTop,
				lineWidth = config.lineWidth,
				rightTop = leftTop + config.opponentHeight / 2 + config.matchMargin + 6 + config.opponentHeight / 2,
			} or nil,
		}
	}
end

---A stub connector into an opponent that does not connect to a lower match.
---@param props {lineWidth: number, rightTop: number}
---@return VNode
function BracketDisplay.ConnectorStub(props)
	return Html.Div{
		classes = {'brkts-connector-stub'},
		children = BracketLineNode{
			height = props.lineWidth .. 'px',
			left = '10px',
			right = 0,
			top = (props.rightTop - props.lineWidth / 2) .. 'px',
		}
	}
end

---@param match MatchGroupUtilMatch
---@param bracketResetMatch MatchGroupUtilMatch?
---@return standardOpponent?
function BracketDisplay.getRunnerUpOpponent(match, bracketResetMatch)
	-- 2 opponents: the runner up is the one that is not the winner, assuming
	-- there is a winner
	if #match.opponents == 2 then
		local winner = (bracketResetMatch or match).winner
		return winner
			and match.opponents[2 + 1 - winner]
			or nil

	-- >2 opponents: wait for the match to be finished, then look at the placement field
	-- TODO remove match.finished requirement
	else
		return match.finished
			and Array.find(match.opponents, function(opponent)
				local place = opponent.placement
				-- in case of reset match: need to even overwrite if placement2 is empty
				if bracketResetMatch then
					place = opponent.placement2
				end

				return place == 2
			end) or nil
	end
end

return BracketDisplay
