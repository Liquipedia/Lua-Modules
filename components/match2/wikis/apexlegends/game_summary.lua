---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomGameSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:Summary/Util')

---@class ApexMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

local GAME_STANDINGS_COLUMNS = {
	{
		sortable = true,
		sortType = 'rank',
		class = 'cell--rank',
		iconClass = 'fas fa-hashtag',
		header = {
			value = 'Rank',
		},
		sortVal = {
			value = function (opponent, idx)
				if opponent.placement == -1 or opponent.status ~= 'S' then
					return idx
				end
				return opponent.placement
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local placementDisplay
					if opponent.status and opponent.status ~= 'S' then
						placementDisplay = '-'
					else
						placementDisplay = SummaryHelper.displayRank(place)
					end
				local icon, color = SummaryHelper.getTrophy(place)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-icon'):addClass(icon):addClass(color):done()
						:tag('span'):wikitext(SummaryHelper.displayRank(placementDisplay)):done()
			end,
		},
	},
	{
		sortable = true,
		sortType = 'team',
		class = 'cell--team',
		iconClass = 'fas fa-users',
		header = {
			value = 'Team',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.name
			end,
		},
		row = {
			value = function (opponent, idx)
				return SummaryHelper.displayOpponent(opponent)
			end,
		},
	},
	{
		sortable = true,
		sortType = 'total-points',
		class = 'cell--total-points',
		iconClass = 'fas fa-star',
		header = {
			value = 'Total Points',
			mobileValue = 'Pts.',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
	},
	{
		sortable = true,
		sortType = 'placements',
		class = 'cell--placements',
		iconClass = 'fas fa-trophy-alt',
		header = {
			value = 'Placement Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
	},
	{
		sortable = true,
		sortType = 'kills',
		class = 'cell--kills',
		iconClass = 'fas fa-skull',
		header = {
			value = 'Kill Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
	},
}
---@param props {bracketId: string, matchId: string, gameIdx: integer}
---@return Html
function CustomGameSummary.getGameByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)

	local game = match.games[props.gameIdx]
	assert(game, 'Error Game ID ' .. tostring(props.gameIdx) .. ' not found')

	game.stream = match.stream

	CustomGameSummary._opponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	local gameSummary = mw.html.create()
	gameSummary:node(CustomGameSummary._createGameTab(game, match.matchId, props.gameIdx, scoringData))

	return gameSummary
end

---@param game table
---@param matchId string
---@param idx integer
---@param scoreData table
---@return Html
function CustomGameSummary._createGameTab(game, matchId, idx, scoreData)
	local page = mw.html.create('div')
			:addClass('panel-content')
			:attr('data-js-battle-royale', 'panel-content')
			:attr('id', matchId .. 'panel' .. idx)

	local gameDetails = page:tag('div')
			:addClass('panel-content__container')
			:attr('role', 'tabpanel')

	local informationList = gameDetails:tag('ul'):addClass('panel-content__game-schedule')
	informationList:tag('li')
			:tag('div')
					:addClass('panel-content__game-schedule__container')
					:node(SummaryHelper.countdownIcon(game, 'panel-content__game-schedule__icon'))
					:node(SummaryHelper.gameCountdown(game))
	if game.map then
		informationList:tag('li')
				:tag('i')
						:addClass('far fa-map')
						:addClass('panel-content__game-schedule__icon')
						:done()
				:tag('span'):wikitext(Page.makeInternalLink(game.map))
	end

	page:node(SummaryHelper.createPointsDistributionTable(scoreData))

	return page:node(CustomGameSummary._createGameStandings(game))
end

---@param game table
---@return Html
function CustomGameSummary._createGameStandings(game)
	local wrapper = mw.html.create('div')
			:addClass('panel-table')
			:attr('data-js-battle-royale', 'table')
	local header = wrapper:tag('div')
			:addClass('panel-table__row')
			:addClass('row--header')
			:attr('data-js-battle-royale', 'header-row')

	Array.forEach(GAME_STANDINGS_COLUMNS, function(column)
		local cell = header:tag('div')
			:addClass('panel-table__cell')
			:addClass(column.class)
			local groupedCell = cell:tag('div'):addClass('panel-table__cell-grouped')
				:tag('i')
						:addClass('panel-table__cell-icon')
						:addClass(column.iconClass)
						:done()
				:tag('span')
						:wikitext(column.header.value)
						:done()
			if (column.sortable and column.sortType) then
				cell:attr('data-sort-type', column.sortType)
				groupedCell:tag('div')
					:addClass('panel-table__sort')
					:tag('i')
						:addClass('far fa-arrows-alt-v')
						:attr('data-js-battle-royale', 'sort-icon')
			end
	end)

	Array.forEach(game.opponents, function (opponent, index)
		local row = wrapper:tag('div'):addClass('panel-table__row'):attr('data-js-battle-royale', 'row')
		Array.forEach(GAME_STANDINGS_COLUMNS, function(column)
			local cell = row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(opponent, index))
			if (column.sortType) then
				cell:attr('data-sort-val', column.sortVal.value(opponent, index)):attr('data-sort-type', column.sortType)
			end
		end)
	end)
	return wrapper
end

function CustomGameSummary._opponents(match)
	-- Add match opponent data to game opponent
	Array.forEach(match.games, function (game)
		game.opponents = Array.map(game.opponents,
			function(gameOpponent, opponentIdx)
				local matchOpponent = match.opponents[opponentIdx]
				local newGameOpponent = Table.merge(matchOpponent, gameOpponent)
				-- These values are only allowed to come from Game and not Match
				newGameOpponent.placement = gameOpponent.placement
				newGameOpponent.score = gameOpponent.score
				newGameOpponent.status = gameOpponent.status
				return newGameOpponent
			end
		)
	end)

	-- Sort game level based on placement
	Array.forEach(match.games, function (game)
		Array.sortInPlaceBy(game.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)
	end)
end

return CustomGameSummary
