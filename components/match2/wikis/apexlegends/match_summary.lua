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
local Ordinal = require('Module:Ordinal')
local Page = require('Module:Page')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay


local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

local MATCH_STATUS_TO_ICON = {
	finished = 'fas fa-check icon--green',
	live = 'fas fa-circle icon--red',
	upcoming = 'fa-clock',
}

local PLACEMENT_BG = {
	'cell--gold',
	'cell--silver',
	'cell--bronze',
	'cell--copper',
}

local TROPHY_COLOR = {
	'icon--gold',
	'icon--silver',
	'icon--bronze',
	'icon--copper',
}

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
	local function createHeader(title, icon)
		return mw.html.create('li')
				:addClass('panel-tabs__list-item')
				:attr('role', 'tab')
				:attr('tabindex', 0)
				:tag('i'):addClass(icon):done()
				:tag('h4'):addClass('panel-tabs__title'):wikitext(title):done()
	end
	local header = mw.html.create('ul'):addClass('panel-tabs__list'):attr('role', 'tablist')
	header:node(createHeader('Overall standings', 'fad fa-list-ol '))

	for idx, game in ipairs(match.games) do
		header:node(createHeader('Game '.. idx, CustomMatchSummary._countdownIcon(game)))
	end

	return mw.html.create('div'):addClass('panel-tabs'):attr('role', 'tabpanel'):node(header)
end

function CustomMatchSummary._createPointsDistributionTable(match)
	local scoring = Table.copy(match.extradata.scoring)
	local wrapper = mw.html.create()
	wrapper:tag('h5')
			:addClass('panel-content__button')
			:addClass('is--collapsed')
			:attr('tabindex', 0)
			:wikitext('Points Distribution')

	local function createItem(icon, iconColor, title, desc)
		return mw.html.create('li'):addClass('panel-content__points-distribution__list-item')
				:tag('span'):addClass('panel-content__points-distribution__icon'):addClass(iconColor)
						:tag('i'):addClass(icon):allDone()
				:tag('span'):addClass('panel-content__points-distribution__title'):wikitext(title):allDone()
				:tag('span'):wikitext(desc):allDone()
	end

	local pointDist = wrapper:tag('div')
			:addClass('panel-content__container')
			:addClass('is--hidden')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')
			:attr('hidden')

	local pointsList = pointDist:tag('ul'):addClass('panel-content__points-distribution')
	pointsList:node(createItem('fas fa-skull', '1 kill', (Table.extract(scoring, 'kill') or '') .. ' kill point'))

	local points = Table.groupBy(scoring, function (_, value)
		return value
	end)
	for point, placements in Table.iter.spairs(points, function (_, a, b)
		return a > b
	end) do
		local title, icon, iconColor
		if Table.size(placements) == 1 then
			local place = Array.extractKeys(placements)[1]
			title = CustomMatchSummary._displayRank(place)
			icon, iconColor = CustomMatchSummary._getIcon(place)
		else
			local placementRange = Array.sortBy(Array.extractKeys(placements), FnUtil.identity)
			title = CustomMatchSummary._displayRank(placementRange[1], placementRange[#placementRange])
			icon, iconColor = CustomMatchSummary._getIcon(placementRange[1])
		end
		pointsList:node(createItem(icon, iconColor, title, point .. ' placement points'))
	end
	return wrapper
end

function CustomMatchSummary._createOverallPage(match)
	local infoArea = mw.html.create('div'):addClass('panel-content'):attr('id', 'panel1')
	-- Schedule
	infoArea:tag('h5'):addClass('panel-content__button'):attr('tabindex', 0):wikitext('Schedule')
	local schedule = infoArea:tag('div')
	schedule:addClass('panel-content__container'):attr('id', 'panelContent1'):attr('role', 'tabpanel')
	local scheduleList = schedule:tag('ul'):addClass('panel-content__game-schedule')
	for idx, game in ipairs(match.games) do
		scheduleList:tag('li')
				:tag('i'):addClass(CustomMatchSummary._countdownIcon(game)):addClass('panel-content__game-schedule__icon'):done()
				:tag('span'):addClass('panel-content__game-schedule__title'):wikitext('Game ', idx, ':'):done()
				:node(CustomMatchSummary._gameCountdown(game)):done()
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
	gameDetails:tag('div')
			:tag('span')
				:tag('i'):addClass(CustomMatchSummary._countdownIcon(game)):addClass('panel-content__game-schedule__icon'):done()
				:wikitext('Game ', idx, ': '):done()
			:node(CustomMatchSummary._gameCountdown(game))
	if CustomMatchSummary._isLive(game) or CustomMatchSummary._isUpcoming(game) then
		gameDetails:tag('div'):node(CustomMatchSummary._gameCountdown(game))
	end
	gameDetails:tag('div'):wikitext(Page.makeInternalLink(game.map))

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
				local icon, color = CustomMatchSummary._getIcon(opponent.placement)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-rank__icon'):addClass(icon):addClass(color):done()
						:tag('span'):addClass('panel-table__cell-rank__text')
								:wikitext(CustomMatchSummary._displayRank(opponent.placement)):done()
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
				return CustomMatchSummary._displayTeam(opponent)
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
				class = function (opponent)
					return PLACEMENT_BG[opponent.placement]
				end,
				value = function (opponent)
					local icon, color = CustomMatchSummary._getIcon(opponent.placement)
					return mw.html.create()
							:tag('i'):addClass('panel-table__cell-game__icon'):addClass(icon):addClass(color):done()
							:tag('span'):addClass('panel-table__cell-game__text')
									:wikitext(CustomMatchSummary._displayRank(opponent.placement)):done()
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
	for idx, game in ipairs(match.games) do
		local gameHeader = header:tag('div'):addClass('panel-table__cell'):addClass('cell--game')
		gameHeader:tag('div'):addClass('panel-table__cell-game'):addClass('cell--game-details')
				:tag('i'):addClass(CustomMatchSummary._countdownIcon(game)):addClass('cell--game-details-icon'):done()
				:tag('p'):addClass('panel-table__cell-game'):addClass('cell--game-details-title'):wikitext('Game ', idx):done()
				:tag('p'):addClass('panel-table__cell-game'):addClass('cell--game-details-date')
						:node(CustomMatchSummary._gameCountdown(game)):done()
		for _, column in ipairs(matchstuff.game) do
			gameHeader:tag('div'):node(column.header.value):addClass('panel-table__cell-game'):addClass(column.class)
		end
	end
	for opponentIdx, opponentMatch in ipairs(match.opponents) do
		local row = wrapper:tag('div'):addClass('panel-table__row')
		for _, column in ipairs(matchstuff) do
			row:tag('div'):node(column.row.value(opponentMatch)):addClass('panel-table__cell'):addClass(column.class)
		end
		for _, game in ipairs(match.games) do
			local gameRow = row:tag('div'):addClass('panel-table__cell'):addClass('cell--game')
			local opponent = Table.merge(opponentMatch, game.extradata.opponents[opponentIdx])
			for _, column in ipairs(matchstuff.game) do
				gameRow:tag('div')
						:node(column.row.value(opponent))
						:addClass('panel-table__cell-game')
						:addClass(column.class)
						:addClass(column.row.class and column.row.class(opponent) or nil)
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
				local icon, color = CustomMatchSummary._getIcon(opponent.placement)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-rank__icon'):addClass(icon):addClass(color):done()
						:tag('span'):addClass('panel-table__cell-rank__text')
								:wikitext(CustomMatchSummary._displayRank(opponent.placement)):done()
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
				return CustomMatchSummary._displayTeam(opponent)
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
		header:tag('div'):node(column.header.value):addClass('panel-table__cell'):addClass(column.class)
	end
	for opponentIdx, opponentMatch in ipairs(match.opponents) do
		local row = wrapper:tag('div'):addClass('panel-table__row')
		local opponent = Table.merge(opponentMatch, game.extradata.opponents[opponentIdx])
		for _, column in ipairs(gamestuff) do
			row:tag('div'):node(column.row.value(opponent)):addClass('panel-table__cell'):addClass(column.class)
		end
	end
	return wrapper
end

function CustomMatchSummary._isUpcoming(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return false
	end
	return NOW < timestamp
end

function CustomMatchSummary._isLive(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return false
	end
	return not CustomMatchSummary._isFinished(game) and NOW >= timestamp
end

function CustomMatchSummary._isFinished(game)
	return game.winner ~= nil
end

function CustomMatchSummary._countdownIcon(game)
	if CustomMatchSummary._isFinished(game) then
		return MATCH_STATUS_TO_ICON.finished
	elseif CustomMatchSummary._isLive(game) then
		return MATCH_STATUS_TO_ICON.live
	elseif CustomMatchSummary._isUpcoming(game) then
		return MATCH_STATUS_TO_ICON.upcoming
	end
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
	return mw.html.create('div'):addClass('panel-content__game-schedule__countdown'):addClass('match-countdown-block')
		:node(require('Module:Countdown')._create(stream))
end

---@param placementStart string|number|nil
---@param placementEnd string|number|nil
---@return string?
function CustomMatchSummary._displayRank(placementStart, placementEnd)
	local places = {}

	if placementStart then
		table.insert(places, Ordinal.toOrdinal(placementStart))
	end

	if placementStart and placementEnd and placementEnd > placementStart then
		table.insert(places, Ordinal.toOrdinal(placementEnd))
	end

	return table.concat(places, ' - ')
end

function CustomMatchSummary._getIcon(place)
	if TROPHY_COLOR[place] then
		return 'fas fa-trophy', TROPHY_COLOR[place]
	end
end

function CustomMatchSummary._displayTeam(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

return CustomMatchSummary
