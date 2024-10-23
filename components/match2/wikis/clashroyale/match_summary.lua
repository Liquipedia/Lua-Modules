---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local NUM_CARDS_PER_PLAYER = 8
local CARD_COLOR_1 = 'blue'
local CARD_COLOR_2 = 'red'
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local DEFAULT_CARD = 'default'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '360px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local isTeamGame = Array.any(match.opponents, function(opponent) return opponent.type == Opponent.team end)
	local games
	if isTeamGame then
		games = CustomMatchSummary._createTeamMatchBody(match)
	else
		games = Array.map(match.games, function (game, gameIndex)
			return CustomMatchSummary._createGame(game, gameIndex, match.date)
		end)
	end

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games,
		MatchSummaryWidgets.Mvp(match.extradata.mvp)
	)}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return Html
function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()

	-- Add game header
	if not Logic.isEmpty(game.header) then
		row:addElement(mw.html.create('div')
			:wikitext(game.header)
			:css('margin', 'auto')
			:css('font-weight', 'bold')
		)
		row:addElement(MatchSummary.Break():create())
	end

	local cardData = {{}, {}}
	for participantKey, participantData in Table.iter.spairs(game.participants or {}) do
		local opponentIndex = tonumber(mw.text.split(participantKey, '_')[1])
		participantData.cards = participantData.cards or {}
		---@type table
		local cards = Array.map(Array.range(1, NUM_CARDS_PER_PLAYER), function(idx)
			return participantData.cards[idx] or DEFAULT_CARD end)
		cards.tower = participantData.cards.tower
		table.insert(cardData[opponentIndex], cards)
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentCardsDisplay{
		data = cardData[1],
		flip = true,
		date = date,
	})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext('Game ' .. gameIndex)
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentCardsDisplay{
		data = cardData[2],
		flip = false,
		date = date,
	})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		row:addElement(mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		)
	end

	return row:create()
end

---@param match MatchGroupUtilMatch
---@return Html[]
function CustomMatchSummary._createTeamMatchBody(match)
	local _, subMatches = Array.groupBy(match.games, Operator.property('subgroup'))
	subMatches = Array.map(subMatches, function(subMatch)
		return {games = subMatch}
	end)

	Array.forEach(subMatches, FnUtil.curry(CustomMatchSummary._getSubMatchOpponentsAndPlayers, match))
	Array.forEach(subMatches, CustomMatchSummary._calculateSubMatchWinner)
	return Array.map(subMatches, function(subMatch, subMatchIndex)
		CustomMatchSummary._createSubMatch(
			subMatch.players,
			subMatchIndex,
			subMatch,
			match.extradata
		):create()
	end)
end

---@param match MatchGroupUtilMatch
---@param subMatch table
---@param subMatchIndex integer
function CustomMatchSummary._getSubMatchOpponentsAndPlayers(match, subMatch, subMatchIndex)
	subMatch.players = CustomMatchSummary._fetchPlayersForSubmatch(subMatchIndex, subMatch, match)
	subMatch.opponents = Array.map(Array.range(1, #subMatch.players), function(opponentIndex)
		local score, status = MatchGroupInputUtil.computeOpponentScore(
			{opponentIndex = opponentIndex},
			FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, subMatch.games)
		)
		return {score = score, status = status}
	end)
end

---@param subMatch table
function CustomMatchSummary._calculateSubMatchWinner(subMatch)
	subMatch.scores = Array.map(subMatch.opponents, Operator.property('score'))

	local subMatchIsFinished = Array.all(subMatch.games, function(game)
		return Logic.isNotEmpty(game.winner)
			or game.resulttype == MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED

	end)
	if not subMatchIsFinished then return end

	subMatch.finished = true
	subMatch.winner = MatchGroupInputUtil.getHighestScoringOpponent(subMatch.opponents)
end

---@param subMatchIndex integer
---@param subMatch table
---@param match MatchGroupUtilMatch
---@return table[]
function CustomMatchSummary._fetchPlayersForSubmatch(subMatchIndex, subMatch, match)
	local players = {{}, {}, hash = {{}, {}}}

	CustomMatchSummary._extractPlayersFromGame(players, subMatch.games[1], match)

	if match.extradata['subgroup' .. subMatchIndex .. 'iskoth'] then
		for gameIndex = 2, #subMatch.games do
			CustomMatchSummary._extractPlayersFromGame(players, subMatch.games[gameIndex], match)
		end
	end

	players.hash = nil

	return players
end

---@param players table
---@param game MatchGroupUtilGame
---@param match MatchGroupUtilMatch
---@return table
function CustomMatchSummary._extractPlayersFromGame(players, game, match)
	for participantKey, participant in Table.iter.spairs(game.participants or {}) do
		participantKey = mw.text.split(participantKey, '_')
		local opponentIndex = tonumber(participantKey[1])
		local match2playerIndex = tonumber(participantKey[2])

		local player = match.opponents[opponentIndex].players[match2playerIndex]

		if not player then
			player = {
				displayName = participant.displayname,
				pageName = participant.name,
			}
		end

		-- make sure we only display each player once
		if not players.hash[opponentIndex][player.pageName] then
			players.hash[opponentIndex][player.pageName] = true
			table.insert(players[opponentIndex], player)
		end
	end

	return players
end
---comment
---@param players table
---@param subMatchIndex integer
---@param subMatch table
---@param extradata table
---@return MatchSummaryRow
function CustomMatchSummary._createSubMatch(players, subMatchIndex, subMatch, extradata)
	local row = MatchSummary.Row()

	row:addClass('brkts-popup-body-game')
		:css('min-height', '32px')

	-- Add submatch header
	if not Logic.isEmpty(extradata['subgroup' .. subMatchIndex .. 'header']) then
		row:addElement(mw.html.create('div')
			:wikitext(extradata['subgroup' .. subMatchIndex .. 'header'])
			:css('margin', 'auto')
			:css('font-weight', 'bold')
		)
		row:addElement(MatchSummary.Break():create())
	end

	-- players left side
	row:addElement(mw.html.create('div')
		:addClass(subMatch.winner == 1 and 'bg-win' or nil)
		:css('align-items', 'center')
		:css('border-radius', '0 12px 12px 0')
		:css('padding', '2px 8px')
		:css('text-align', 'right')
		:css('width', '40%')
		:node(OpponentDisplay.BlockPlayers{
			opponent = {players = players[1]},
			overflow = 'ellipsis',
			showLink = true,
			flip = true,
		})
	)

	local scoreDisplay = table.concat(subMatch.scores, ' - ')
	local scoreElement
	if extradata['subgroup' .. subMatchIndex .. 'iskoth'] then
		scoreElement = mw.html.create('div')
			:node(mw.html.create('div'):wikitext(scoreDisplay))
			:node(mw.html.create('div')
				:css('font-size', '85%')
				:wikitext(Abbreviation.make('KOTH', 'King of the Hill'))
			)
	end

	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:node(scoreElement or scoreDisplay)
	)

	-- players right side
	row:addElement(mw.html.create('div')
		:addClass(subMatch.winner == 2 and 'bg-win' or nil)
		:css('align-items', 'center')
		:css('border-radius', '12px 0 0 12px')
		:css('padding', '2px 8px')
		:css('text-align', 'left')
		:css('width', '40%')
		:node(OpponentDisplay.BlockPlayers{
			opponent = {players = players[2]},
			overflow = 'ellipsis',
			showLink = true,
			flip = false,
		})
	)

	return row
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(isWinner) then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param args table
---@return Html
function CustomMatchSummary._opponentCardsDisplay(args)
	local cardDataSets = args.data
	local flip = args.flip
	local date = args.date

	local color = flip and CARD_COLOR_2 or CARD_COLOR_1

	local sideWrapper = mw.html.create('div')
		:css('display', 'flex')
		:css('flex-direction', 'column')

	for _, cardData in ipairs(cardDataSets) do
		local wrapper = mw.html.create('div')
			:css('flex-basis', '1px')
			:css('display', 'inline-flex')
			:css('flex-direction', (flip and 'row' or 'row-reverse'))
			:css('align-items', 'center')
		local wrapperCards = mw.html.create('div')
			:css('display', 'flex')
			:css('flex-direction', 'column')

		local cardDisplays = {}
		for _, card in ipairs(cardData) do
			table.insert(cardDisplays, mw.html.create('div')
				:addClass('brkts-popup-side-color-' .. color)
				:addClass('brkts-champion-icon')
				:node(CharacterIcon.Icon{
					character = card,
					date = date,
					size = '48px'
				})
			)
		end

		local display
		for cardIndex, card in ipairs(cardDisplays) do
			-- break the card rows into fragments of 4 cards each
			if cardIndex % 4 == 1 then
				wrapperCards:node(display)
				display = mw.html.create('div')
					:addClass('brkts-popup-body-element-thumbs')
					:addClass(flip and 'brkts-popup-body-element-thumbs-right' or nil)
			end

			display:node(card)
		end
		wrapperCards:node(display)
		wrapper:node(wrapperCards)

		if Logic.isNotEmpty(cardData.tower) then
			local towerCardDisplay = mw.html.create('div')
					:addClass('brkts-popup-body-element-thumbs')
					:tag('div')
						:addClass('brkts-popup-side-color-' .. color)
						:addClass('brkts-champion-icon')
						:node(CharacterIcon.Icon{
							character = cardData.tower,
							date = date
						})
			wrapper:node(towerCardDisplay)
		end

		sideWrapper:node(wrapper)
	end

	return sideWrapper
end

return CustomMatchSummary
