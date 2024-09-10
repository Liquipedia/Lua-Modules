---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Placement = require('Module:Placement')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

--[[
Module containing display components for match summaries of free-for-all matches.
]]
local FfaMatchSummary = {propTypes = {}, types = {}}

FfaMatchSummary.types.Config = TypeUtil.struct({
	Footer = 'function',
	GamePlacement = 'function',
	GameScore = 'function',
	GameScoreHeader = 'function',
	Opponent = 'function',
	TotalScore = 'function',
	TotalScoreHeader = 'function',
	gameHeaderAbbr = 'string',
	gameHeaderTitle = 'string',
	rowHeight = 'number',
	showPlacement = 'boolean',
	showScore = 'boolean',
})
FfaMatchSummary.types.ConfigOptions = TypeUtil.struct(
	Table.mapValues(FfaMatchSummary.types.Config.struct, TypeUtil.optional)
)

FfaMatchSummary.propTypes.FfaMatchSummary = {
	config = TypeUtil.optional(FfaMatchSummary.types.ConfigOptions),
	match = MatchGroupUtil.types.Match,
}

--[[
Display component for the popup match summary of a free-for-all match. The data
is presented as a table, with opponents as rows and games of the match as
columns.

Many aspects of this component can be customized via composition. To do so,
wrap this component within another component, while passing custom options to
props.config. See StarcraftFfaMatchSummary as an example of how to customize
this component.
]]
function FfaMatchSummary.FfaMatchSummary(props)
	DisplayUtil.assertPropTypes(props, FfaMatchSummary.propTypes.FfaMatchSummary)
	local match = props.match

	local propsConfig = props.config or {}
	local showScore = Logic.nilOr(propsConfig.showScore, not match.noScore)
	local showPlacement = Logic.nilOr(
		propsConfig.showPlacement,
		Logic.readBoolOrNil(match.extradata.showplacement),
		showScore or #match.games > 1
	)
	local config = {
		Footer = propsConfig.Footer or FfaMatchSummary.Footer,
		GamePlacement = propsConfig.GamePlacement or FfaMatchSummary.GamePlacement,
		GameScore = propsConfig.GameScore or FfaMatchSummary.GameScore,
		GameScoreHeader = propsConfig.GameScoreHeader or FfaMatchSummary.GameScoreHeader,
		Opponent = propsConfig.Opponent or FfaMatchSummary.Opponent,
		TotalScore = propsConfig.TotalScore or FfaMatchSummary.TotalScore,
		TotalScoreHeader = propsConfig.TotalScoreHeader or FfaMatchSummary.TotalScoreHeader,
		gameHeaderAbbr = propsConfig.gameHeaderAbbr or 'R',
		gameHeaderTitle = propsConfig.gameHeaderTitle or 'Round ',
		rowHeight = propsConfig.rowHeight or 36,
		showPlacement = showPlacement,
		showScore = showScore,
	}

	local opponentIxs = Table.map(match.opponents, function(ix, opponent) return opponent, ix end)
	local sortedOpponents = Array.sortBy(match.opponents, function(opponent)
		return {
			-(opponent.score or -1),
			opponent.placement or math.huge,
			opponentIxs[opponent],
		}
	end)
	local sortedOpponentIxs = Array.map(sortedOpponents, function(opponent) return opponentIxs[opponent] end)

	local gridLeftNode = FfaMatchSummary.GridLeft({
		config = config,
		match = props.match,
		opponentIxs = sortedOpponentIxs,
	})
	local gridRightNode = FfaMatchSummary.GridRight({
		config = config,
		match = props.match,
		opponentIxs = sortedOpponentIxs,
	})

	local leftBasis = (showPlacement and 36 or 0)
		+ 144 -- opponent column
		+ (showScore and 36 or 0)
	local rightBasis = #match.games * (showScore and 2 or 1) * 36

	-- Clamp the width to between 300px and 576px.
	-- 300px is the basis width of placement, opponent, and 5 games columns without score.
	-- 576px is the basis width of placement, opponent, total score, and 5 games columns with score.
	local width = math.min(math.max(300, leftBasis + rightBasis), 576)

	local gridNode = mw.html.create('div'):addClass('ffa-match-summary-grid')
		:node(gridLeftNode:css('flex-basis', leftBasis .. 'px'))
		:node(
			mw.html.create('div'):addClass('ffa-match-summary-right')
				:node(gridRightNode)
		)

	return mw.html.create('div'):addClass('ffa-match-summary')
		:css('width', width .. 'px')
		:node(FfaMatchSummary.Header({match = match}))
		:node(gridNode)
		:node(FfaMatchSummary.Maps({match = match, config = config}))
		:node(match.comment and FfaMatchSummary.Comment({comment = match.comment}) or nil)
		:node(config.Footer({match = match}))
end

FfaMatchSummary.propTypes.Header = {
	match = MatchGroupUtil.types.Match,
}

function FfaMatchSummary.Header(props)
	local countdownNode = props.match.dateIsExact
		and DisplayHelper.MatchCountdownBlock(props.match)
			:addClass('brkts-popup-countdown')
		or nil

	return mw.html.create('div'):addClass('ffa-match-summary-header')
		:node(countdownNode)
end

FfaMatchSummary.propTypes.GridLeftRight = {
	config = FfaMatchSummary.types.Config,
	match = MatchGroupUtil.types.Match,
	opponentIxs = TypeUtil.array('number'),
}

--[[
Left half of the grid, containing match placement, opponent, and total score columns.
]]
function FfaMatchSummary.GridLeft(props)
	local config = props.config
	local match = props.match

	local showTotalScore = config.showScore and #match.games > 1

	local function BackgroundRows()
		local bgRowsNode = mw.html.create('div'):addClass('ffa-match-summary-bg-rows')
		bgRowsNode:tag('div'):addClass('ffa-match-summary-header-bg-row')
			:css('grid-area', 'header 1 / 1 / span 1 / -1')
		for rowIx = 1, #match.opponents do
			bgRowsNode:tag('div'):addClass('ffa-match-summary-body-bg-row')
				:css('grid-area', 'body ' .. rowIx .. ' / 1 / span 1 / -1')
		end
		return bgRowsNode
	end

	local function Header()
		local placementNode = config.showPlacement
			and FfaMatchSummary.AbbrCell('#', 'Placement')
				:addClass('ffa-match-summary-placement')
				:css('grid-area', 'header / placement')
			or nil

		local opponentNode = FfaMatchSummary.OpponentHeader({opponents = match.opponents})
			:css('grid-area', 'header / opponent')

		local scoreNode = showTotalScore
			and config.TotalScoreHeader()
				:css('grid-area', 'header / score')
			or nil

		return mw.html.create('div'):addClass('ffa-match-summary-grid-header')
			:node(placementNode):node(opponentNode):node(scoreNode)
	end

	local function Body()
		local bodyNode = mw.html.create('div'):addClass('ffa-match-summary-grid-body')

		if config.showPlacement then
			for _, cellNode in ipairs(FfaMatchSummary.PlacementCells(props)) do
				bodyNode:node(cellNode)
			end
		end

		for rowIx, opponentIx in ipairs(props.opponentIxs) do
			local opponent = match.opponents[opponentIx]

			local opponentNode = config.Opponent({match = match, opponent = opponent, opponentIx = opponentIx})
				:css('grid-area', 'body ' .. rowIx .. ' / opponent')

			local scoreNode = showTotalScore
				and config.TotalScore({opponent = opponent})
					:css('grid-area', 'body ' .. rowIx .. ' / score')
				or nil

			bodyNode:node(opponentNode):node(scoreNode)
		end

		return bodyNode
	end

	local templateColumns = Array.extend(
		config.showPlacement and '[placement] minmax(min-content, 36fr)' or nil,
		'[opponent] 200fr',
		showTotalScore and '[score] minmax(min-content, 36fr)' or nil
	)
	local templateRows = {
		'[header] ' .. (config.showScore and '72px' or '36px'),
		'repeat(' .. #match.opponents .. ', [body] ' .. config.rowHeight .. 'px)',
	}
	return mw.html.create('div'):addClass('ffa-match-summary-grid-left')
		:css('grid-template-columns', table.concat(templateColumns, ' '))
		:css('grid-template-rows', table.concat(templateRows, ' '))
		:node(BackgroundRows())
		:node(Header())
		:node(Body())
end

function FfaMatchSummary.PlacementCells(props)
	local match = props.match

	-- Placement cell spanning ties
	local function Cell(rowIx, group)
		local placement = match.opponents[group[1]].placement

		local bgClass = #match.bracketData.advanceSpots == 0 and placement
			and Placement.getBgClass(placement)
			or nil

		local label = Placement.RangeLabel({rowIx, rowIx + #group - 1})
		return FfaMatchSummary.AbbrCell(label)
			:addClass('ffa-match-summary-placement')
			:addClass(bgClass)
			:css('grid-area', 'body ' .. rowIx .. ' / placement / span ' .. #group .. ' / span 1')
	end

	-- Group placements to determine ties
	local groups = Array.groupBy(
		props.opponentIxs,
		function(ix) return match.opponents[ix].placement or ('unique' .. ix) end
	)

	-- Loop through placement groups and draw cells
	local cells = {}
	local rowIx = 1
	for _, group in ipairs(groups) do
		table.insert(cells, Cell(rowIx, group))
		rowIx = rowIx + #group
	end

	-- Use separate grid elements to draw pbg backgrounds
	if #match.bracketData.advanceSpots > 0 then
		for rowIx_ = 1, #match.opponents do
			local spot = match.bracketData.advanceSpots[rowIx_]
			local bgCell = mw.html.create('div')
				:addClass(FfaMatchSummary.getAdvanceClass(spot and spot.bg or 'down'))
				:css('grid-area', 'body ' .. rowIx .. ' / placement')
			table.insert(cells, bgCell)
		end
	end

	return cells
end

--[[
Right half of the grid, containing placement and score columns for each game.
]]
function FfaMatchSummary.GridRight(props)
	local config = props.config
	local match = props.match

	local function BackgroundRows()
		local bgRowsNode = mw.html.create('div'):addClass('ffa-match-summary-bg-rows')
		bgRowsNode:tag('div'):addClass('ffa-match-summary-header-bg-row')
			:css('grid-area', 'header 1 / 1 / body 1 / -1')

		for rowIx = 1, #match.opponents do
			bgRowsNode:tag('div'):addClass('ffa-match-summary-body-bg-row')
				:css('grid-area', 'body ' .. rowIx .. ' / 1 / span 1 / -1')
		end
		return bgRowsNode
	end

	local function Header()
		local headerNode = mw.html.create('div'):addClass('ffa-match-summary-grid-header')

		--First row
		for gameIx, _ in ipairs(match.games) do
			local gameNode
			if config.showScore then
				gameNode = FfaMatchSummary.AbbrCell(config.gameHeaderTitle .. gameIx)
					:addClass('ffa-match-summary-game-title')
					:css('grid-area', 'header 1 / placement ' .. gameIx .. ' / span 1 / span 2')
			else
				if #match.games == 1 then
					gameNode = FfaMatchSummary.AbbrCell('#', 'Placement')
				else
					gameNode = FfaMatchSummary.AbbrCell(config.gameHeaderAbbr .. gameIx, config.gameHeaderTitle .. gameIx)
				end
				gameNode:addClass('ffa-match-summary-game-placement')
					:css('grid-area', 'header / placement ' .. gameIx)
			end
			headerNode:node(gameNode)
		end

		-- Second row
		if config.showScore then
			for gameIx, _ in ipairs(match.games) do
				local placementNode = FfaMatchSummary.AbbrCell('P', 'Placement')
					:addClass('ffa-match-summary-game-placement')
					:css('grid-area', 'header 2 / placement ' .. gameIx)

				local scoreNode = config.GameScoreHeader()
					:css('grid-area', 'header 2 / score ' .. gameIx)

				headerNode:node(placementNode):node(scoreNode)
			end
		end

		return headerNode
	end

	local function Body()
		local bodyNode = mw.html.create('div'):addClass('ffa-match-summary-grid-body')
		for rowIx, opponentIx in ipairs(props.opponentIxs) do
			for gameIx, game in ipairs(match.games) do
				local opponent = game.opponents[opponentIx]
				local placementNode = config.GamePlacement({gameIx = gameIx, opponent = opponent, opponentIx = opponentIx})
					:css('grid-area', 'body ' .. rowIx .. ' / placement ' .. gameIx)

				local scoreNode = config.showScore
					and config.GameScore({gameIx = gameIx, opponent = opponent, opponentIx = opponentIx})
						:css('grid-area', 'body ' .. rowIx .. ' / score ' .. gameIx)
					or nil

				bodyNode:node(placementNode):node(scoreNode)
			end
		end
		return bodyNode
	end

	local gameTemplateColumns = Array.extend(
		'[placement] min-content',
		config.showScore and ' [score] min-content' or nil
	)
	local templateRows = Array.extend(
		'[header] 36px',
		config.showScore and '[header] 36px' or nil,
		'repeat(' .. #match.opponents .. ', [body] ' .. config.rowHeight .. 'px)'
	)
	return mw.html.create('div'):addClass('ffa-match-summary-grid-right')
		:css('grid-template-columns', 'repeat(' .. #match.games .. ', ' .. table.concat(gameTemplateColumns, ' ') .. ')')
		:css('grid-template-rows', table.concat(templateRows, ' '))
		:node(BackgroundRows())
		:node(Header())
		:node(Body())
end

FfaMatchSummary.propTypes.Maps = {
	config = FfaMatchSummary.types.Config,
	match = MatchGroupUtil.types.Match,
}

--[[
Maps played, and map comments. Collapses the map display if all games are played on the same map.
]]
function FfaMatchSummary.Maps(props)
	DisplayUtil.assertPropTypes(props, FfaMatchSummary.propTypes.Maps)
	local match = props.match

	local maps = Table.map(match.games, function(ix, game) return game.map or '', true end)
	local uniqueMap = String.nilIfEmpty(Table.uniqueKey(maps))

	-- Map and game comments
	local mapsNode = mw.html.create('div'):addClass('ffa-match-summary-maps')
	if uniqueMap then
		mapsNode:tag('div'):addClass('ffa-match-summary-unique-map')
			:wikitext('<b>Map</b>: [[' .. uniqueMap .. ']]')
	end
	for gameIx, game in ipairs(match.games) do
		if game.comment or (game.map and not uniqueMap) then
			local mapText = game.map and not uniqueMap
				and ': ' .. DisplayHelper.MapAndStatus(game)
				or nil

			mapsNode:tag('div'):addClass('ffa-match-summary-map')
				:wikitext('<b>' .. props.config.gameHeaderTitle .. gameIx .. '</b>' .. (mapText or ''))

			if game.comment then
				local commentNode = mapsNode:tag('div'):addClass('ffa-match-summary-game-comment')
					:wikitext(game.comment)
				DisplayUtil.applyOverflowStyles(commentNode, 'wrap')
			end
		end
	end

	return mapsNode
end

--[[
Match comment.
]]
function FfaMatchSummary.Comment(props)
	local commentNode = mw.html.create('div'):addClass('ffa-match-summary-comment')
		:wikitext(props.comment)
	return DisplayUtil.applyOverflowStyles(commentNode, 'wrap')
end

function FfaMatchSummary.abbrNode(text, abbrTitle)
	return mw.html.create('abbr'):attr('title', abbrTitle):wikitext(text)
end

--[[
A cell with horizontally and vertically centered text and optionally an abbreviation.
]]
function FfaMatchSummary.AbbrCell(text, abbrTitle)
	local contentNode = mw.html.create('div'):addClass('ffa-match-summary-cell-content')
	if abbrTitle then
		contentNode:node(FfaMatchSummary.abbrNode(text, abbrTitle))
	else
		contentNode:wikitext(text)
	end
	return mw.html.create('div'):addClass('ffa-match-summary-cell')
		:node(contentNode)
end

--[[
Header cell for the opponent column.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.OpponentHeader(props)
	local opponentTypes = Table.map(props.opponents, function(_, opponent) return opponent.type, true end)
	local uniqueOpponentType = Table.uniqueKey(opponentTypes)
	local opponentHeaderText =
		uniqueOpponentType == 'team' and 'Teams'
			or uniqueOpponentType == 'solo' and 'Players'
			or 'Opponents'

	return FfaMatchSummary.AbbrCell(opponentHeaderText)
		:addClass('ffa-match-summary-opponent')
end

--[[
Header cell for the total score column.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.TotalScoreHeader()
	return FfaMatchSummary.AbbrCell('∑', 'Total Score')
		:addClass('ffa-match-summary-total-score')
end

--[[
Header cell for the score column of a game.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.GameScoreHeader()
	return FfaMatchSummary.AbbrCell('S', 'Score')
		:addClass('ffa-match-summary-game-score')
end

function FfaMatchSummary.getOpponentBgClass(opponent, match)
	if #match.bracketData.advanceSpots > 0 then
		return opponent.advanceBg
			and FfaMatchSummary.getAdvanceClass(opponent.advanceBg)
			or nil
	else
		return opponent.placement
			and Placement.getBgClass(opponent.placement)
			or nil
	end
end

--[[
Table cell showing an opponent. Appears in the opponent column.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.Opponent(props)
	local contentNode = OpponentDisplay.BlockOpponent({
		opponent = props.opponent,
		overflow = props.opponent.type == 'team' and 'hidden' or 'ellipsis',
		teamStyle = 'bracket',
	})
	return mw.html.create('div')
		:addClass('ffa-match-summary-cell ffa-match-summary-opponent')
		:addClass(FfaMatchSummary.getOpponentBgClass(props.opponent, props.match))
		:node(contentNode)
end

--[[
Table cell showing the total, match-level score of an opponent.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.TotalScore(props)
	return FfaMatchSummary.AbbrCell(OpponentDisplay.InlineScore(props.opponent))
		:addClass('ffa-match-summary-total-score')
end

--[[
Table cell showing the placement of a game-level opponent in a game of a match.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.GamePlacement(props)
	local opponent = props.opponent
	return FfaMatchSummary.AbbrCell(opponent.placement or '')
		:addClass('ffa-match-summary-game-placement')
		:addClass(opponent.placement and Placement.getBgClass(opponent.placement))
end

--[[
Table cell showing the score of a game-level opponent in a game of a match.

This is the default implementation used by FfaMatchSummary.
]]
function FfaMatchSummary.GameScore(props)
	return FfaMatchSummary.AbbrCell(props.opponent.score)
		:addClass('ffa-match-summary-game-score')
end

--[[
Content appearing at the bottom of a match summary popup.

This is the default implementation used by FfaMatchSummary, which does nothing.
]]
function FfaMatchSummary.Footer(props)
	return mw.html.create('div'):addClass('ffa-match-summary-footer')
end

--[[
Converts an advance specification to a css class that sets its background.

Example:
FfaMatchSummary.getAdvanceClass('stayup')
-- returns 'bg-stayup'
]]
function FfaMatchSummary.getAdvanceClass(advanceBg)
	return 'bg-' .. advanceBg
end

return Class.export(FfaMatchSummary)
