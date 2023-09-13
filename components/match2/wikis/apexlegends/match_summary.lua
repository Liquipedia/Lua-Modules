---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = mw.html.create('div'):addClass('navigation-content-container')

	matchSummary:node(CustomMatchSummary._createHeader(match))
	matchSummary:node(CustomMatchSummary._createOverallPage(match))
	for idx in ipairs(match.games) do
		matchSummary:node(CustomMatchSummary._createGameTab(match, idx))
	end

	return tostring(matchSummary)
end

function CustomMatchSummary._createHeader(match)
	local function createHeader(title)
		return mw.html.create('li')
				:addClass('panel-tabs__list-item')
				:attr('role', 'tab')
				:attr('tabindex', 0)
				:node(mw.html.create('h4'):addClass('panel-tabs__title'):wikitext(title))
	end
	local header = mw.html.create('ul'):addClass('panel-tabs__list'):attr('role', 'tablist')
	header:node(createHeader('Overall standings'))

	for idx in ipairs(match.games) do
		header:node(createHeader('Game '.. idx))
	end

	return mw.html.create('div'):addClass('panel-tabs'):attr('role', 'tabpanel'):node(header)
end

function CustomMatchSummary._createPointsDistributionTable(match)
	local wrapper = mw.html.create(nil)
	local scoring = match.extradata.scoring
	wrapper:tag('h5'):addClass('panel-content__button'):addClass('is--collapsed'):attr('tabindex', 0):wikitext('Points Distribution')

	local pointsList = wrapper:tag('div')
	pointsList:addClass('panel-content__container'):addClass('is--hidden'):attr('id', 'panelContent1'):attr('role', 'tabpanel'):attr('hidden')
	pointsList:tag('div'):wikitext('1 kill ', Table.extract(scoring, 'kill'), ' kill point')
	local points = Table.groupBy(scoring, function (_, value)
		return value
	end)
	for point, placements in Table.iter.spairs(points, function (_, a, b)
		return a > b
	end) do
		if Table.size(placements) == 1 then
			pointsList:tag('div'):wikitext(Array.extractKeys(placements)[1], ' ', point, ' placement points')
		else
			local placementRange = Array.sortBy(Array.extractKeys(placements), FnUtil.identity)
			pointsList:tag('div'):wikitext(placementRange[1], ' - ', placementRange[#placementRange], ' ', point, ' placement points')
		end
	end
	return wrapper
end

function CustomMatchSummary._createOverallPage(match)
	local infoArea = mw.html.create('div'):addClass('panel-content'):attr('id', 'panel1')
	-- Schedule
	infoArea:tag('h5'):addClass('panel-content__button'):attr('tabindex', 0):wikitext('Schedule')
	local schedule = infoArea:tag('div')
	schedule:addClass('panel-content__container'):attr('id', 'panelContent1'):attr('role', 'tabpanel')
	for idx, game in ipairs(match.games) do
		schedule:tag('div'):wikitext('Game ', idx, ': '):node(CustomMatchSummary._gameCountdown(game))
	end

	infoArea:node(CustomMatchSummary._createPointsDistributionTable(match))

	return tostring(infoArea) .. tostring(CustomMatchSummary._createOverallStandings(match))
end

function CustomMatchSummary._createGameTab(match, idx)
	local game = match.games[idx]
	local infoArea = mw.html.create('div'):addClass('panel-content'):attr('id', 'panel1')
	-- Schedule
	infoArea:tag('h5'):addClass('panel-content__button'):attr('tabindex', 0):wikitext('Game Details')
	local gameDetails = infoArea:tag('div')
	gameDetails:addClass('panel-content__container'):attr('id', 'panelContent1'):attr('role', 'tabpanel')
	gameDetails:tag('div'):wikitext('Game ', idx, ': '):node(CustomMatchSummary._gameCountdown(game))
	gameDetails:tag('div'):node(CustomMatchSummary._gameCountdown(game))
	gameDetails:tag('div'):wikitext(game.map)

	-- Help Text
	infoArea:node(CustomMatchSummary._createPointsDistributionTable(match))

	return tostring(infoArea) .. tostring(CustomMatchSummary._createGameStandings(match, idx))
end

local matchstuff = {
	{
		class = 'cell--status',
		header = {
			value = '',
		},
		row = {
			value = function (opponent)
				return '-'
			end,
		},
	},
	{
		class = 'cell--rank',
		header = {
			value = 'Rank',
		},
		row = {
			value = function (opponent)
				return opponent.placement
			end,
		},
	},
	{
		class = 'cell--team',
		header = {
			value = 'Team',
		},
		row = {
			value = function (opponent)
				return opponent.name
			end,
		},
	},
	{
		class = 'cell--total-points',
		header = {
			value = 'Total Points',
		},
		row = {
			value = function (opponent)
				return opponent.score
			end,
		},
	},
	game = {
		{
			class = 'cell--game-placement',
			header = {
				value = 'P',
			},
			row = {
				value = function (opponent)
					return opponent.placement
				end,
			},
		},
		{
			class = 'cell--game-kills',
			header = {
				value = 'K',
			},
			row = {
				value = function (opponent)
					return opponent.scoreBreakdown.kills
				end,
			},
		},
	}
}

function CustomMatchSummary._createOverallStandings(match)
	local wrapper = mw.html.create('div'):addClass('panel-table')
	local header = wrapper:tag('div'):addClass('panel-table__row'):addClass('row--header')
	for _, column in ipairs(matchstuff) do
		header:tag('div'):wikitext(column.header.value):addClass('panel-table__cell'):addClass(column.class)
	end
	for _, game in ipairs(match.games) do
		local gameHeader = header:tag('div'):addClass('panel-table__cell'):addClass('cell--game')
		gameHeader:tag('div'):addClass('panel-table__cell-game'):addClass('cell--game-details')
				:tag('p'):addClass('panel-table__cell-game'):addClass('cell--game-details-title'):wikitext('Game Num'):done()
				:tag('p'):addClass('panel-table__cell-game'):addClass('cell--game-details-date'):wikitext('Date'):done()
		for _, column in ipairs(matchstuff.game) do
			gameHeader:tag('div'):wikitext(column.header.value):addClass('panel-table__cell-game'):addClass(column.class)
		end
	end
	for opponentIdx, opponentMatch in ipairs(match.opponents) do
		local row = wrapper:tag('div'):addClass('panel-table__row')
		for _, column in ipairs(matchstuff) do
			row:tag('div'):wikitext(column.row.value(opponentMatch)):addClass('panel-table__cell'):addClass(column.class)
		end
		for _, game in ipairs(match.games) do
			local gameRow = row:tag('div'):addClass('panel-table__cell'):addClass('cell--game')
			local opponent = Table.merge(opponentMatch, game.extradata.opponents[opponentIdx])
			for _, column in ipairs(matchstuff.game) do
				gameRow:tag('div'):wikitext(column.row.value(opponent)):addClass('panel-table__cell-game'):addClass(column.class)
			end
		end
	end
	return wrapper
end

local gamestuff = {
	{
		class = 'cell--button',
		header = {
			value = '',
		},
		row = {
			value = function (opponent)
				return '\\/'
			end,
		},
	},
	{
		class = 'cell--rank',
		header = {
			value = 'Rank',
		},
		row = {
			value = function (opponent)
				return opponent.placement
			end,
		},
	},
	{
		class = 'cell--team',
		header = {
			value = 'Team',
		},
		row = {
			value = function (opponent)
				return opponent.name
			end,
		},
	},
	{
		class = 'cell--total-points',
		header = {
			value = 'Total Points',
		},
		row = {
			value = function (opponent)
				return opponent.score
			end,
		},
	},
	{
		class = 'cell--placements',
		header = {
			value = 'Placement Points',
		},
		row = {
			value = function (opponent)
				return opponent.scoreBreakdown.placePoints
			end,
		},
	},
	{
		class = 'cell--kills',
		header = {
			value = 'Kill Points',
		},
		row = {
			value = function (opponent)
				return opponent.scoreBreakdown.killPoints
			end,
		},
	},
}

function CustomMatchSummary._createGameStandings(match, idx)
	local game = match.games[idx]
	local wrapper = mw.html.create('div'):addClass('panel-table')
	local header = wrapper:tag('div'):addClass('panel-table__row'):addClass('row--header')
	for _, column in ipairs(gamestuff) do
		header:tag('div'):wikitext(column.header.value):addClass('panel-table__cell'):addClass(column.class)
	end
	for opponentIdx, opponentMatch in ipairs(match.opponents) do
		local row = wrapper:tag('div'):addClass('panel-table__row')
		local opponent = Table.merge(opponentMatch, game.extradata.opponents[opponentIdx])
		for _, column in ipairs(gamestuff) do
			row:tag('div'):wikitext(column.row.value(opponent)):addClass('panel-table__cell'):addClass(column.class)
		end
	end
	return wrapper
end

function CustomMatchSummary._gameCountdown(game)
	--- TODO Add VOD for completed games
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return
	end
	local dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' ' .. Timezone.getTimezoneString('UTC')

	local stream = Table.merge(game.stream, {
		date = dateString,
		finished = game.finished and 'true' or nil,
	})
	return mw.html.create('div'):addClass('match-countdown-block')
		:css('text-align', 'center')
		-- Workaround for .brkts-popup-body-element > * selector
		:css('display', 'block')
		:node(require('Module:Countdown')._create(stream))
end

return CustomMatchSummary
