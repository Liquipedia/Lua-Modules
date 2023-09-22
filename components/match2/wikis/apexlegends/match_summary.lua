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
local VodLink = require('Module:VodLink')

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

---@param args table
---@return string
function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	match.scoringTable = CustomMatchSummary._createScoringData(match)
	Array.forEach(match.games, function(game)
		game.scoringTable = match.scoringTable
	end)

	match = CustomMatchSummary._opponents(match)

	local matchSummary = mw.html.create('div'):addClass('navigation-content-container')

	local addNode = FnUtil.curry(matchSummary.node, matchSummary)
	addNode(CustomMatchSummary._createHeader(match))
	addNode(CustomMatchSummary._createOverallPage(match))
	Array.forEach(Array.map(match.games, CustomMatchSummary._createGameTab), addNode)

	addNode(CustomMatchSummary._createFooter(match))

	return tostring(matchSummary)
end

function CustomMatchSummary._opponents(match)
	-- Add match opponent data to game opponent and the other way around
	Array.forEach(match.games, function (game)
		game.extradata.opponents = Array.map(game.extradata.opponents, function (opponent, opponentIdx)
			return Table.merge(match.opponents[opponentIdx], opponent)
		end)
	end)
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.extradata.opponents[idx]
		end)
	end)

	if not CustomMatchSummary._isFinished(match) then
		return match
	end

	-- Sort match level based on score (placement works too)
	table.sort(match.opponents, function (a, b)
		return a.placement < b.placement
	end)

	-- Sort game level based on placement
	Array.forEach(match.games, function (game)
		table.sort(game.extradata.opponents, function (a, b)
			return a.placement < b.placement
		end)
	end)

	return match
end

---@param match table
---@return {kill: number, placement: {rangeStart: integer, rangeEnd: integer, score:number}[]}
function CustomMatchSummary._createScoringData(match)
	local scoreSettings = match.extradata.scoring

	local scoreKill = Table.extract(scoreSettings, 'kill')
	local scorePlacement = {}

	local points = Table.groupBy(scoreSettings, function (_, value)
		return value
	end)

	for point, placements in Table.iter.spairs(points, function (_, a, b)
		return a > b
	end) do
		local placementRange = Array.sortBy(Array.extractKeys(placements), FnUtil.identity)
		table.insert(scorePlacement, {
			rangeStart = placementRange[1],
			rangeEnd = placementRange[#placementRange],
			score = point,
		})
	end

	match.extradata.scoring = nil

	return {
		kill = scoreKill,
		placement = scorePlacement,
	}
end

local matchStandingsColumns = {
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
		iconClass = 'fas fa-hashtag',
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
		iconClass = 'fas fa-users',
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
		iconClass = 'fas fa-star',
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
			class = 'panel-table__cell__game-placement',
			iconClass = 'fas fa-trophy-alt',
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
			class = 'panel-table__cell__game-kills',
			iconClass = 'fas fa-skull',
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

local gameStandingsColumns = {
	{
		class = 'cell--button',
		header = {
			value = '',
		},
		row = {
			value = function (opponent)
				return ''
			end,
		},
	},
	{
		class = 'cell--rank',
		iconClass = 'fas fa-hashtag',
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
		iconClass = 'fas fa-users',
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
		iconClass = 'fas fa-star',
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
		iconClass = 'fas fa-trophy-alt',
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
		iconClass = 'fas fa-skull',
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

---@param match table
---@return Html
function CustomMatchSummary._createFooter(match)
	return mw.html.create('div')
end

---@param match table
---@return Html
function CustomMatchSummary._createHeader(match)
	local function createHeader(title, icon)
		return mw.html.create('li')
				:addClass('panel-tabs__list-item')
				:attr('role', 'tab')
				:attr('tabindex', 0)
				:tag('i'):addClass('panel-tabs__list-icon'):addClass(icon):done()
				:tag('h4'):addClass('panel-tabs__title'):wikitext(title):done()
	end
	local header = mw.html.create('ul')
			:addClass('panel-tabs__list')
			:attr('role', 'tablist')
			:node(createHeader('Overall standings', 'fad fa-list-ol '))

	Array.forEach(match.games, function (game, idx)
		header:node(createHeader('Game '.. idx, CustomMatchSummary._countdownIcon(game)))
	end)

	return mw.html.create('div')
			:addClass('panel-tabs')
			:attr('role', 'tabpanel')
			:node(header)
end

---@param match table
---@return Html
function CustomMatchSummary._createPointsDistributionTable(match)
	local wrapper = mw.html.create()
	wrapper:tag('h5')
			:addClass('panel-content__button')
			:addClass('is--collapsed')
			:attr('tabindex', 0)
			:wikitext('Points Distribution')

	local function createItem(icon, iconColor, title, score, type)
		return mw.html.create('li'):addClass('panel-content__points-distribution__list-item')
				:tag('span'):addClass('panel-content__points-distribution__icon'):addClass(iconColor)
						:tag('i'):addClass(icon):allDone()
				:tag('span'):addClass('panel-content__points-distribution__title'):wikitext(title):allDone()
				:tag('span'):wikitext(score, ' ', type, ' ', 'point', (score ~= 1) and 's' or nil):allDone()
	end

	local pointsList = wrapper:tag('div')
			:addClass('panel-content__container')
			:addClass('is--hidden')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')
			:attr('hidden')
			:tag('ul')
					:addClass('panel-content__points-distribution')

	pointsList:node(createItem('fas fa-skull', nil, '1 kill', match.scoringTable.kill, 'kill'))

	Array.forEach(match.scoringTable.placement, function (slot)
		local title = CustomMatchSummary._displayRank(slot.rangeStart, slot.rangeEnd)
		local icon, iconColor = CustomMatchSummary._getIcon(slot.rangeStart)

		pointsList:node(createItem(icon, iconColor, title, slot.score, 'placement'))
	end)

	return wrapper
end

---@param match table
---@return Html
function CustomMatchSummary._createOverallPage(match)
	local infoArea = mw.html.create('div')
			:addClass('panel-content')
			:attr('id', 'panel1')
			:tag('h5')
					:addClass('panel-content__button')
					:attr('tabindex', 0)
					:wikitext('Schedule')
					:done()

	local scheduleList = infoArea:tag('div')
			:addClass('panel-content__container')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')
			:tag('ul')
					:addClass('panel-content__game-schedule')

	Array.forEach(match.games, function (game, idx)
		scheduleList:tag('li')
				:tag('i')
						:addClass(CustomMatchSummary._countdownIcon(game))
						:addClass('panel-content__game-schedule__icon')
						:done()
				:tag('span')
						:addClass('panel-content__game-schedule__title')
						:wikitext('Game ', idx, ':')
						:done()
				:node(CustomMatchSummary._gameCountdown(game))
	end)

	infoArea:node(CustomMatchSummary._createPointsDistributionTable(match))

	return mw.html.create()
			:node(infoArea)
			:node(CustomMatchSummary._createMatchStandings(match))
end

---@param game table
---@param idx integer
---@return Html
function CustomMatchSummary._createGameTab(game, idx)
	local infoArea = mw.html.create('div')
			:addClass('panel-content')
			:attr('id', 'panel1')
			:tag('h5')
					:addClass('panel-content__button')
					:attr('tabindex', 0)
					:wikitext('Game Details')
					:done()

	local gameDetails = infoArea:tag('div')
			:addClass('panel-content__container')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')
			:tag('div')
					:tag('span')
							:tag('i')
									:addClass(CustomMatchSummary._countdownIcon(game))
									:addClass('panel-content__game-schedule__icon')
									:done()
							:wikitext('Game ', idx, ': ')
							:done()
					:done()
			:node(CustomMatchSummary._gameCountdown(game))

	if CustomMatchSummary._isLive(game) or CustomMatchSummary._isUpcoming(game) then
		gameDetails:tag('div'):node(CustomMatchSummary._gameCountdown(game))
	end
	gameDetails:tag('div'):wikitext(Page.makeInternalLink(game.map))

	infoArea:node(CustomMatchSummary._createPointsDistributionTable(game))

	return mw.html.create()
			:node(infoArea)
			:node(CustomMatchSummary._createGameStandings(game))
end

---@param match table
---@return Html
function CustomMatchSummary._createMatchStandings(match)
	local wrapper = mw.html.create('div')
			:addClass('panel-table')

	local header = wrapper:tag('div')
			:addClass('panel-table__row')
			:addClass('row--header')
			:tag('div')
					:addClass('panel-table__navigate')
					:addClass('navigate--right')
					:wikitext('>')
					:done()

	Array.forEach(matchStandingsColumns, function(column)
		header:tag('div')
				:addClass('panel-table__cell')
				:addClass(column.class)
				:tag('i')
						:addClass('panel-table__cell-icon')
						:addClass(column.iconClass)
						:done()
				:tag('span')
						:wikitext(column.header.value)
						:done()
	end)

	Array.forEach(match.games, function (game, idx)
		local gameContainer = header:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--game')

		gameContainer:tag('div')
				:addClass('panel-table__cell__game-head')
				:tag('div')
						:addClass('panel-table__cell__game-title')
						:tag('i')
								:addClass(CustomMatchSummary._countdownIcon(game))
								:addClass('panel-table__cell-icon')
								:done()
						:tag('span')
								:addClass('panel-table__cell-text')
								:wikitext('Game ', idx)
								:done()
						:done()
				:tag('p')
						:addClass('panel-table__cell__game-date')
						:node(CustomMatchSummary._gameCountdown(game))
						:done()

		local gameDetails = gameContainer:tag('div'):addClass('panel-table__cell__game-details')
		Array.forEach(matchStandingsColumns.game, function(column)
			gameDetails:tag('div')
					:addClass(column.class)
					:tag('i')
							:addClass('panel-table__cell-icon')
							:addClass(column.iconClass)
							:done()
					:tag('span')
							:wikitext(column.header.value)
							:done()
		end)
	end)

	Array.forEach(match.opponents, function (opponentMatch)
		local row = wrapper:tag('div'):addClass('panel-table__row')

		Array.forEach(matchStandingsColumns, function(column)
			row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(opponentMatch))
		end)

		Array.forEach(opponentMatch.games, function(opponent)
			local gameRow = row:tag('div'):addClass('panel-table__cell'):addClass('cell--game')

			Array.forEach(matchStandingsColumns.game, function(column)
				gameRow:tag('div')
						:node(column.row.value(opponent))
						:addClass(column.class)
						:addClass(column.row.class and column.row.class(opponent) or nil)
			end)
		end)
	end)

	return wrapper
end

---@param game table
---@return Html
function CustomMatchSummary._createGameStandings(game)
	local wrapper = mw.html.create('div'):addClass('panel-table')
	local header = wrapper:tag('div')
			:addClass('panel-table__row')
			:addClass('row--header')

	Array.forEach(gameStandingsColumns, function(column)
		header:tag('div')
			:addClass('panel-table__cell')
			:addClass(column.class)
			:tag('i')
					:addClass('panel-table__cell-icon')
					:addClass(column.iconClass)
					:done()
			:node(column.header.value)
	end)

	Array.forEach(game.extradata.opponents, function (opponent)
		local row = wrapper:tag('div'):addClass('panel-table__row')
		Array.forEach(gameStandingsColumns, function(column)
			row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(opponent))
		end)
	end)
	return wrapper
end

---@param game table
---@return boolean
function CustomMatchSummary._isUpcoming(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return false
	end
	return NOW < timestamp
end

---@param game table
---@return boolean
function CustomMatchSummary._isLive(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return false
	end
	return not CustomMatchSummary._isFinished(game) and NOW >= timestamp
end

---@param game table
---@return boolean
function CustomMatchSummary._isFinished(game)
	return game.winner ~= nil
end

---@param game table
---@return string?
function CustomMatchSummary._countdownIcon(game)
	if CustomMatchSummary._isFinished(game) then
		return MATCH_STATUS_TO_ICON.finished
	elseif CustomMatchSummary._isLive(game) then
		return MATCH_STATUS_TO_ICON.live
	elseif CustomMatchSummary._isUpcoming(game) then
		return MATCH_STATUS_TO_ICON.upcoming
	end
end

---Creates a countdown block for a given game
---Attaches any VODs of the game as well
---@param game table
---@return Html?
function CustomMatchSummary._gameCountdown(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return
	end
	-- TODO Use local TZ
	local dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' ' .. Timezone.getTimezoneString('UTC')

	local stream = Table.merge(game.stream, {
		date = dateString,
		finished = CustomMatchSummary._isFinished(game) and 'true' or nil,
	})

	return mw.html.create('div'):addClass('panel-content__game-schedule__countdown'):addClass('match-countdown-block')
			:node(require('Module:Countdown')._create(stream))
			:node(game.vod and VodLink.display{vod = game.vod} or nil)
end

---@param placementStart string|number|nil
---@param placementEnd string|number|nil
---@return string
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

---@param place integer
---@return string? icon
---@return string? iconColor
function CustomMatchSummary._getIcon(place)
	if TROPHY_COLOR[place] then
		return 'fas fa-trophy', TROPHY_COLOR[place]
	end
end

---@param opponent standardOpponent
---@return Html
function CustomMatchSummary._displayTeam(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

return CustomMatchSummary
