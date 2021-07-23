local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Math = require('Module:Math')
local OpponentDisplay = require('Module:OpponentDisplay')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local html = mw.html

local BracketDisplay = {propTypes = {}, types = {}}

-- Called by MatchGroup/Display
function BracketDisplay.luaGet(_, args)
	return BracketDisplay.BracketContainer({
		bracketId = args[1],
		config = BracketDisplay.configFromArgs(args),
	})
end

function BracketDisplay.configFromArgs(args)
	return {
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

BracketDisplay.types.BracketConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	OpponentEntry = 'function',
	headerHeight = 'number',
	headerMargin = 'number',
	hideRoundTitles = 'boolean',
	lineWidth = 'number',
	matchHasDetails = 'function',
	matchMargin = 'number',
	matchWidth = 'number',
	matchWidthMobile = 'number',
	opponentHeight = 'number',
	qualifiedHeader = 'string?',
	roundHorizontalMargin = 'number',
	scoreWidth = 'number',
})
BracketDisplay.types.BracketConfigOptions = TypeUtil.struct(
	Table.mapValues(BracketDisplay.types.BracketConfig.struct, TypeUtil.optional)
)

BracketDisplay.propTypes.BracketContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(BracketDisplay.types.BracketConfigOptions),
}

--[[
Display component for a tournament bracket. The bracket is specified by ID.
The component fetches the match data from LPDB or page variables.
]]
function BracketDisplay.BracketContainer(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.BracketContainer)
	return BracketDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		config = props.config,
	})
end

BracketDisplay.propTypes.Bracket = {
	bracket = MatchGroupUtil.types.MatchGroup,
	config = TypeUtil.optional(BracketDisplay.types.BracketConfigOptions),
}

--[[
Display component for a tournament bracket. Match data is specified in the
input.
]]
function BracketDisplay.Bracket(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.Bracket)

	local defaultConfig = DisplayHelper.getGlobalConfig()
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		OpponentEntry = propsConfig.OpponentEntry or BracketDisplay.OpponentEntry,
		headerHeight = propsConfig.headerHeight or defaultConfig.headerHeight,
		headerMargin = propsConfig.headerMargin or defaultConfig.headerMargin,
		hideRoundTitles = propsConfig.hideRoundTitles or false,
		lineWidth = propsConfig.lineWidth or defaultConfig.lineWidth,
		matchHasDetails = propsConfig.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
		matchMargin = propsConfig.matchMargin or math.floor(defaultConfig.opponentHeight / 4),
		matchWidth = propsConfig.matchWidth or defaultConfig.matchWidth,
		matchWidthMobile = propsConfig.matchWidthMobile or defaultConfig.matchWidthMobile,
		opponentHeight = propsConfig.opponentHeight or defaultConfig.opponentHeight,
		qualifiedHeader = propsConfig.qualifiedHeader or defaultConfig.qualifiedHeader,
		roundHorizontalMargin = propsConfig.roundHorizontalMargin or defaultConfig.roundHorizontalMargin,
		scoreWidth = propsConfig.scoreWidth or defaultConfig.scoreWidth,
	}

	local layoutsByMatchId = BracketDisplay.computeBracketLayout(props.bracket, config)

	local bracketNode = html.create('div'):addClass('brkts-bracket')
		:css('--match-width', config.matchWidth .. 'px')
		:css('--match-width-mobile', config.matchWidthMobile .. 'px')
		:css('--score-width', config.scoreWidth .. 'px')
		:css('--round-horizontal-margin', config.roundHorizontalMargin .. 'px')

	-- Draw all top level subtrees of the bracket. These are subtrees rooted
	-- at matches that do not advance to higher rounds.
	for _, matchId in ipairs(props.bracket.headMatchIds) do
		local nodeProps = {
			config = config,
			layoutsByMatchId = layoutsByMatchId,
			matchId = matchId,
			matchesById = props.bracket.matchesById,
		}
		bracketNode
			:node(BracketDisplay.NodeHeader(nodeProps))
			:node(BracketDisplay.NodeBody(nodeProps))
	end

	return html.create('div'):addClass('brkts-main brkts-main-dev brkts-main-dev-2')
		:node(bracketNode)
end

BracketDisplay.types.Layout = TypeUtil.struct({
	height = 'number',
	lowerNodeMarginTop = 'number',
	matchHeight = 'number',
	matchMarginTop = 'number',
	mid = 'number',
	showHeader = 'boolean',
})

--[[
Computes certain layout properties of nodes in the bracket tree.
]]
function BracketDisplay.computeBracketLayout(bracket, config)
	-- Computes the layout of a match and everything to its left.
	local computeNodeLayout = FnUtil.memoizeY(function(matchId, computeNodeLayout)
		local match = bracket.matchesById[matchId]

		-- Recurse on lower round matches
		local lowerLayouts = Array.map(
			match.bracketData.lowerMatches,
			function(lowerMatch) return computeNodeLayout(lowerMatch.matchId) end
		)

		-- Compute partial sums of heights of lower round matches
		local heightSums = Math.partialSums(
			Array.map(lowerLayouts, function(layout) return layout.height end)
		)

		-- Don't show the header if it's disabled. Also don't show the header
		-- if it is the first match of a round because a higher round match can
		-- show it instead.
		local isFirstChild = bracket.upperMatchIds[matchId]
			and matchId == bracket.matchesById[bracket.upperMatchIds[matchId]].bracketData.lowerMatches[1].matchId
		local showHeader = match.bracketData.header
			and not config.hideRoundTitles
			and not isFirstChild

		local headerFullHeight = showHeader
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
			showHeader = showHeader,
		}
	end)

	return Table.mapValues(bracket.matchesById, function(match) return computeNodeLayout(match.matchId) end)
end

-- Computes the vertical offset of a match with its lower round matches
function BracketDisplay.alignMatchWithLowerNodes(match, lowerLayouts, heightSums, opponentHeight)
	local matchHeight = #match.opponents * opponentHeight

	-- Show a connector line without joints if there is a single lower round
	-- match advancing an opponent that is placed near the middle of this match.
	local showSingleStraightLine = false
	if #lowerLayouts == 1 then
		local opponentIx = match.bracketData.lowerMatches[1].opponentIx
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
		local opponentIx = match.bracketData.lowerMatches[1].opponentIx
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

BracketDisplay.propTypes.NodeHeader = {
	config = BracketDisplay.types.BracketConfig,
	layoutsByMatchId = TypeUtil.table('string', BracketDisplay.types.Layout),
	matchId = 'string',
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}

--[[
Display component for the headers of a node in the bracket tree. Draws a row of
headers for the match, everything to the left of it, and for the qualification
spots.
]]
function BracketDisplay.NodeHeader(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeHeader)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config

	if not layout.showHeader then
		return nil
	end

	local headerNode = html.create('div'):addClass('brkts-round-header')
		:css('margin', config.headerMargin .. 'px 0 ' .. math.max(0, config.headerMargin - config.matchMargin) .. 'px')

	-- Traverse the bracket to find the other headers in the same row
	local bracketDatas = {}
	local matchId = props.matchId
	while matchId do
		local bracketData = props.matchesById[matchId].bracketData
		table.insert(bracketDatas, 1, bracketData)
		matchId = 0 < #bracketData.lowerMatches and bracketData.lowerMatches[1].matchId or nil
	end

	for _, bracketData in ipairs(bracketDatas) do
		local hasBracketResetMatch = bracketData.bracketResetMatchId
			and props.matchesById[bracketData.bracketResetMatchId]
		headerNode:node(
			BracketDisplay.MatchHeader({
				header = bracketData.header,
				height = config.headerHeight,
			})
				:addClass(hasBracketResetMatch and 'brkts-br-wrapper' or nil)
				:css('--skip-round', bracketData.skipRound)
		)
	end

	if match.bracketData.qualWin then
		headerNode:node(
			BracketDisplay.MatchHeader({
				header = config.qualifiedHeader or '!q',
				height = config.headerHeight,
			})
				:addClass('brkts-qualified-header')
				:css('--qual-skip', match.bracketData.qualSkip)
		)
	end

	return headerNode
end

BracketDisplay.propTypes.MatchHeader = {
	height = 'number',
	header = 'string',
}

--[[
Display component for a header to a match.
]]
function BracketDisplay.MatchHeader(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.MatchHeader)

	local options = DisplayHelper.expandHeader(props.header)

	local headerNode = html.create('div'):addClass('brkts-header brkts-header-div')
		:css('height', props.height .. 'px')
		:css('line-height', props.height - 11 .. 'px')
		:wikitext(options[1])

	-- Don't emit brkts-header-option if there is only one option. This is
	-- because the JavaScript module for changing headers supports only text,
	-- and will eat up tags like <abbr>.
	if #options > 1 then
		for _, option in ipairs(options) do
			headerNode:node(
				html.create('div'):addClass('brkts-header-option'):wikitext(option)
			)
		end
	end

	return headerNode
end

BracketDisplay.propTypes.NodeBody = {
	config = BracketDisplay.types.BracketConfig,
	layoutsByMatchId = TypeUtil.table('string', BracketDisplay.types.Layout),
	matchId = 'string',
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}

--[[
Display component for a node in the bracket tree, which consists of a match and
all the lower round matches leading up to it. Also includes qualification spots
and line connectors between lower round matches, the current match, and
qualification spots.
]]
function BracketDisplay.NodeBody(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeBody)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config

	-- Matches from lower rounds
	local lowerNode
	if 0 < #match.bracketData.lowerMatches then
		lowerNode = html.create('div'):addClass('brkts-round-lower')
			:css('margin-top', layout.lowerNodeMarginTop .. 'px')
		for _, lowerMatch in ipairs(match.bracketData.lowerMatches) do
			local childProps = Table.merge(props, {matchId = lowerMatch.matchId})
			lowerNode
				:node(BracketDisplay.NodeHeader(childProps))
				:node(BracketDisplay.NodeBody(childProps))
		end
	end

	-- Include results from bracketResetMatch
	local bracketResetMatch = match.bracketData.bracketResetMatchId
		and props.matchesById[match.bracketData.bracketResetMatchId]
	if bracketResetMatch then
		match = MatchGroupUtil.mergeBracketResetMatch(match, bracketResetMatch)
	end

	-- Current match
	local matchNode = BracketDisplay.Match({
		MatchSummaryContainer = config.MatchSummaryContainer,
		OpponentEntry = config.OpponentEntry,
		match = match,
		matchHasDetails = config.matchHasDetails,
		opponentHeight = config.opponentHeight,
	})
		:css('margin-top', layout.matchMarginTop .. 'px')
		:css('margin-bottom', config.matchMargin .. 'px')

	-- Third place match
	local thirdPlaceMatch = match.bracketData.thirdPlaceMatchId
		and props.matchesById[match.bracketData.thirdPlaceMatchId]
	local thirdPlaceHeaderNode
	local thirdPlaceMatchNode
	if thirdPlaceMatch then
		thirdPlaceHeaderNode = BracketDisplay.MatchHeader({
			header = thirdPlaceMatch.bracketData.header or '!tp',
			height = config.headerHeight,
		})
			:css('margin-top', 20 + config.headerMargin .. 'px')
			:css('margin-bottom', config.headerMargin .. 'px')
		thirdPlaceMatchNode = BracketDisplay.Match({
			MatchSummaryContainer = config.MatchSummaryContainer,
			OpponentEntry = config.OpponentEntry,
			match = thirdPlaceMatch,
			matchHasDetails = config.matchHasDetails,
			opponentHeight = config.opponentHeight,
		})
	end

	local centerNode = html.create('div'):addClass('brkts-round-center')
		:addClass(bracketResetMatch and 'brkts-br-wrapper' or nil)
		:node(matchNode)
		:node(thirdPlaceHeaderNode)
		:node(thirdPlaceMatchNode)

	-- Qualifier entries
	local qualWinNode
	if match.bracketData.qualWin then
		local opponent = match.winner
			and match.opponents[match.winner]
			or MatchGroupUtil.createOpponent({
				type = 'literal',
				name = match.bracketData.qualWinLiteral or '',
			})
		qualWinNode = BracketDisplay.Qualified({
			OpponentEntry = config.OpponentEntry,
			height = config.opponentHeight,
			opponent = opponent,
		})
			:css('margin-top', layout.matchMarginTop + layout.matchHeight / 2 - config.opponentHeight / 2 .. 'px')
			:css('margin-bottom', config.matchMargin .. 'px')
	end

	local qualLoseNode
	if match.bracketData.qualLose then
		local opponent = BracketDisplay.getRunnerUpOpponent(match)
			or MatchGroupUtil.createOpponent({
				type = 'literal',
				name = match.bracketData.qualLoseLiteral or '',
			})
		qualLoseNode = BracketDisplay.Qualified({
			OpponentEntry = config.OpponentEntry,
			height = config.opponentHeight,
			opponent = opponent,
		})
			:css('margin-top', config.matchMargin + 6 .. 'px')
			:css('margin-bottom', config.matchMargin .. 'px')
	end

	local qualNode
	if qualWinNode or qualLoseNode then
		qualNode = html.create('div'):addClass('brkts-round-qual')
			:node(qualWinNode)
			:node(qualLoseNode)
	end

	return html.create('div'):addClass('brkts-round-body')
		:node(lowerNode)
		:node(lowerNode and BracketDisplay.NodeLowerConnectors(props) or nil)
		:node(centerNode)
		:node(qualNode and BracketDisplay.NodeQualConnectors(props) or nil)
		:node(qualNode)
end

BracketDisplay.propTypes.Match = {
	OpponentEntry = 'function',
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
	matchHasDetails = 'function',
	opponentHeight = 'number',
}

--[[
Display component for a match in a bracket. Draws one row for each opponent,
and an icon for the match summary popup.
]]
function BracketDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.Match)
	local matchNode = html.create('div'):addClass('brkts-match brkts-match-popup-wrapper')

	for ix, opponent in ipairs(props.match.opponents) do
		local opponentEntryNode = props.OpponentEntry({
			displayType = 'bracket',
			height = props.opponentHeight,
			opponent = opponent,
		})
			:addClass(ix == #props.match.opponents and 'brkts-opponent-entry-last' or nil)
			:css('height', props.opponentHeight .. 'px')
		DisplayHelper.addOpponentHighlight(opponentEntryNode, opponent)
		matchNode:node(opponentEntryNode)
	end

	if props.matchHasDetails(props.match) then
		local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
			bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
			matchId = props.match.matchId,
		})

		local matchSummaryPopupNode = html.create('div'):addClass('brkts-match-info-popup')
			:node(matchSummaryNode)

		matchNode
			:node(
				html.create('div'):addClass('brkts-match-info-icon')
					-- Vertically align the middle of the match with the middle
					-- of the 12px icon. The -1 is for the top border of the match.
					:css('top', #props.match.opponents * props.opponentHeight / 2 - 12 / 2 - 1 .. 'px')
			)
			:node(matchSummaryPopupNode)
	end

	return matchNode
end

BracketDisplay.propTypes.Qualified = {
	OpponentEntry = 'function',
	height = 'number',
	opponent = MatchGroupUtil.types.Opponent,
}

--[[
Display component for a qualification spot.
]]
function BracketDisplay.Qualified(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.Qualified)

	local opponentEntryNode = props.OpponentEntry({
		displayType = 'bracket-qualified',
		height = props.height,
		opponent = props.opponent,
	})
		:addClass('brkts-opponent-entry-last')
		:css('height', props.height .. 'px')
	DisplayHelper.addOpponentHighlight(opponentEntryNode, props.opponent)

	return html.create('div'):addClass('brkts-qualified')
		:node(opponentEntryNode)
end

-- Connector lines between a match and its lower matches
BracketDisplay.propTypes.NodeLowerConnectors = BracketDisplay.propTypes.NodeBody
function BracketDisplay.NodeLowerConnectors(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeLowerConnectors)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config
	local lowerMatches = match.bracketData.lowerMatches

	local lowerLayouts = Array.map(
		lowerMatches,
		function(lowerMatch) return props.layoutsByMatchId[lowerMatch.matchId] end
	)

	-- Compute partial sums of heights of lower round matches
	local heightSums = Math.partialSums(
		Array.map(lowerLayouts, function(l) return l.height end)
	)

	-- Compute joints of connectors
	local jointIxs = {}
	local jointIxAbove = 0
	for ix = math.ceil(#lowerMatches / 2), 1, -1 do
		jointIxAbove = jointIxAbove + 1
		jointIxs[lowerMatches[ix].opponentIx] = jointIxAbove
	end
	local jointIxBelow = 0
	-- middle lower match is repeated if odd
	for ix = math.floor(#lowerMatches / 2) + 1, #lowerMatches, 1 do
		jointIxBelow = jointIxBelow + 1
		jointIxs[lowerMatches[ix].opponentIx] = jointIxBelow
	end
	local jointCount = math.max(jointIxAbove, jointIxBelow)

	local lowerConnectorsNode = mw.html.create('div')
		:addClass('brkts-round-lower-connectors')
		:css('--skip-round', match.bracketData.skipRound)

	-- Draw connectors between lower round matches and this match
	for ix, x in ipairs(lowerMatches) do
		local lowerLayout = lowerLayouts[ix]
		local leftTop = layout.lowerNodeMarginTop + heightSums[ix] + lowerLayout.mid
		local rightTop = layout.matchMarginTop + ((x.opponentIx - 1) + 0.5) * config.opponentHeight
		local jointLeft = (config.roundHorizontalMargin - 2) * jointIxs[x.opponentIx] / (jointCount + 1)

		local segment1Node = html.create('div'):addClass('brkts-line')
			:css('height', config.lineWidth .. 'px')
			:css('width', jointLeft + config.lineWidth / 2 .. 'px')
			:css('left', '0')
			:css('top', leftTop - config.lineWidth / 2 .. 'px')

		local segment2Node = html.create('div'):addClass('brkts-line')
			:css('height', math.abs(leftTop - rightTop) .. 'px')
			:css('width', config.lineWidth .. 'px')
			:css('top', math.min(leftTop, rightTop) .. 'px')
			:css('left', jointLeft - config.lineWidth / 2 .. 'px')

		local segment3Node = html.create('div'):addClass('brkts-line')
			:css('height', config.lineWidth .. 'px')
			:css('left', jointLeft - config.lineWidth / 2 .. 'px')
			:css('right', '0')
			:css('top', rightTop - config.lineWidth / 2 .. 'px')

		lowerConnectorsNode
			:node(segment1Node)
			:node(segment2Node)
			:node(segment3Node)
	end

	-- Draw line stubs for opponents not connected to a lower round match
	for opponentIx, _ in ipairs(match.opponents) do
		local rightTop = layout.matchMarginTop + ((opponentIx - 1) + 0.5) * config.opponentHeight
		if not jointIxs[opponentIx] then
			local stubNode = html.create('div'):addClass('brkts-line')
				:css('height', config.lineWidth .. 'px')
				:css('left', 10 .. 'px')
				:css('right', '0')
				:css('top', rightTop - config.lineWidth / 2 .. 'px')
			lowerConnectorsNode:node(stubNode)
		end
	end

	return lowerConnectorsNode
end

BracketDisplay.propTypes.NodeQualConnectors = BracketDisplay.propTypes.NodeBody

-- Connector lines between a match and its qualified spots
function BracketDisplay.NodeQualConnectors(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.NodeQualConnectors)
	local match = props.matchesById[props.matchId]
	local layout = props.layoutsByMatchId[props.matchId]
	local config = props.config

	local qualConnectorsNode = mw.html.create('div')
		:addClass('brkts-round-qual-connectors')
		:css('--qual-skip', match.bracketData.qualSkip)

	-- Qualified winner connector
	local leftTop = layout.matchMarginTop + layout.matchHeight / 2
	local lineNode = html.create('div'):addClass('brkts-line')
		:css('height', config.lineWidth .. 'px')
		:css('right', '0')
		:css('left', '0')
		:css('top', leftTop - config.lineWidth / 2 .. 'px')
	qualConnectorsNode:node(lineNode)

	-- Qualified loser connector
	if match.bracketData.qualLose then
		local rightTop = leftTop + config.opponentHeight / 2 + config.matchMargin + 6 + config.opponentHeight / 2
		local jointRight = 11

		local segment1Node = html.create('div'):addClass('brkts-line')
			:css('width', config.lineWidth .. 'px')
			:css('height', rightTop - leftTop .. 'px')
			:css('right', jointRight - config.lineWidth / 2 .. 'px')
			:css('top', leftTop .. 'px')

		local segment2Node = html.create('div'):addClass('brkts-line')
			:css('height', config.lineWidth .. 'px')
			:css('right', '0')
			:css('width', jointRight + config.lineWidth / 2 .. 'px')
			:css('top', rightTop - config.lineWidth / 2 .. 'px')

		qualConnectorsNode:node(segment1Node):node(segment2Node)
	end

	return qualConnectorsNode
end

function BracketDisplay.getRunnerUpOpponent(match)
	-- 2 opponents: the runner up is the one that is not the winner, assuming
	-- there is a winner
	if #match.opponents == 2 then
		return match.winner
			and match.opponents[2 + 1 - match.winner]
			or nil

	-- >2 opponents: wait for the match to be finished, then look at the placement field
	-- TODO remove match.finished requirement
	else
		return match.finished
			and Array.find(match.opponents, function(opponent) return opponent.placement == 2 end)
			or nil
	end
end

--[[
Display component for an opponent in a bracket match. Shows the name and flag
of the opponent, as well as the opponent's scores.

This is the default opponent entry component. Specific wikis may override this
by passing in a different props.OpponentEntry in the Bracket component.
]]
function BracketDisplay.OpponentEntry(props)
	local opponentEntry = OpponentDisplay.BracketOpponentEntry(props.opponent)
	if props.displayType == 'bracket' then
		opponentEntry:addScores(props.opponent)
	end
	return opponentEntry.root
end

return Class.export(BracketDisplay)
