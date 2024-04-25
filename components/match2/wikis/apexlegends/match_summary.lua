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

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

local MATCH_STATUS_TO_ICON = {
	finished = 'fas fa-check icon--green',
	live = 'fas fa-circle icon--red',
	upcoming = 'fas fa-clock',
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

local STATUS_ICONS = {
	up = 'fas fa-chevron-double-up',
	stayup = 'fas fa-chevron-up',
	stay = 'fas fa-equals',
	staydown = 'fas fa-chevron-down',
	down = 'fas fa-skull',
}

local MATCH_STANDING_COLUMNS = {
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
				return opponent.placement ~= -1 and opponent.placement or idx
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local icon, color = CustomMatchSummary._getTrophy(place)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-icon'):addClass(icon):addClass(color):done()
						:tag('span'):wikitext(CustomMatchSummary._displayRank(place)):done()
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
				return CustomMatchSummary._displayOpponent(opponent)
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
					local icon, color = CustomMatchSummary._getTrophy(opponent.placement)
					return mw.html.create()
							:tag('i')
								:addClass('panel-table__cell-icon')
								:addClass(icon)
								:addClass(color)
								:done()
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
				return opponent.placement ~= -1 and opponent.placement or idx
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local icon, color = CustomMatchSummary._getTrophy(place)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-icon'):addClass(icon):addClass(color):done()
						:tag('span'):wikitext(CustomMatchSummary._displayRank(place)):done()
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
				return CustomMatchSummary._displayOpponent(opponent)
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

---@param args table
---@return string
function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	match.scoringTable = CustomMatchSummary._createScoringData(match)
	Array.forEach(match.games, function(game)
		game.scoringTable = match.scoringTable
		game.stream = match.stream
	end)

	match = CustomMatchSummary._opponents(match)

	local matchSummary = mw.html.create()

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
			local opp = Table.merge(match.opponents[opponentIdx], opponent)
			-- These values are only allowed to come from Game and not Match
			opp.placement = opponent.placement
			opp.score = opponent.score
			opp.status = opponent.status
			return opp
		end)
	end)
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.extradata.opponents[idx]
		end)
	end)

	local placementSortFunction = function(opponent1, opponent2)
		if opponent1.placement == opponent2.placement or not opponent1.placement or not opponent2.placement then
			if opponent1.score and opponent2.score and opponent1.score ~= opponent2.score then
				return opponent1.score > opponent2.score
			else
				return (opponent1.name or '') < (opponent2.name or '')
			end
		end
		return opponent1.placement < opponent2.placement
	end

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, placementSortFunction)

	-- Sort game level based on placement
	Array.forEach(match.games, function (game)
		Array.sortInPlaceBy(game.extradata.opponents, FnUtil.identity, placementSortFunction)
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

	return {
		kill = scoreKill,
		placement = scorePlacement,
	}
end

---@param match table
---@return Html
function CustomMatchSummary._createFooter(match)
	return mw.html.create('div')
end

---@param match table
---@return Html
function CustomMatchSummary._createHeader(match)
	local function createHeader(title, icon, idx)
		return mw.html.create('li')
				:addClass('panel-tabs__list-item')
				:attr('data-js-battle-royale', 'panel-tab')
				:attr('data-js-battle-royale-content-target-id', 'panel' .. idx)
				:attr('role', 'tab')
				:attr('tabindex', 0)
				:tag('i'):addClass('panel-tabs__list-icon'):addClass(icon):done()
				:tag('h4'):addClass('panel-tabs__title'):wikitext(title):done()
	end
	local header = mw.html.create('ul')
			:addClass('panel-tabs__list')
			:attr('role', 'tablist')
			:node(createHeader('Overall standings', 'fad fa-list-ol', 0))

	Array.forEach(match.games, function (game, idx)
		header:node(createHeader('Game '.. idx, CustomMatchSummary._countdownIcon(game), idx))
	end)

	return mw.html.create('div')
			:addClass('panel-tabs')
			:attr('role', 'tabpanel')
			:node(header)
end

---@param match table
---@return Html
function CustomMatchSummary._createPointsDistributionTable(match)
	local wrapper = mw.html.create('div')
			:addClass('panel-content__collapsible')
			:addClass('is--collapsed')
			:attr('data-js-battle-royale', 'collapsible')
	local button = wrapper:tag('h5')
			:addClass('panel-content__button')
			:attr('data-js-battle-royale', 'collapsible-button')
			:attr('tabindex', 0)
			button:tag('i')
				:addClass('far fa-chevron-up')
				:addClass('panel-content__button-icon')
			button:tag('span'):wikitext('Points Distribution')

	local function createItem(icon, iconColor, title, score, type)
		return mw.html.create('li'):addClass('panel-content__points-distribution__list-item')
				:tag('span'):addClass('panel-content__points-distribution__icon'):addClass(iconColor)
						:tag('i'):addClass(icon):allDone()
				:tag('span'):addClass('panel-content__points-distribution__title'):wikitext(title):allDone()
				:tag('span'):wikitext(score, ' ', type, ' ', 'point', (score ~= 1) and 's' or nil):allDone()
	end

	local pointsList = wrapper:tag('div')
			:addClass('panel-content__container')
			:attr('data-js-battle-royale', 'collapsible-container')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')
			:attr('hidden')
			:tag('ul')
					:addClass('panel-content__points-distribution')

	pointsList:node(createItem('fas fa-skull', nil, '1 kill', match.scoringTable.kill, 'kill'))

	Array.forEach(match.scoringTable.placement, function (slot)
		local title = CustomMatchSummary._displayRank(slot.rangeStart, slot.rangeEnd)
		local icon, iconColor = CustomMatchSummary._getTrophy(slot.rangeStart)

		pointsList:node(createItem(icon, iconColor, title, slot.score, 'placement'))
	end)

	return wrapper
end

---@param match table
---@return Html
function CustomMatchSummary._createOverallPage(match)
	local page = mw.html.create('div')
			:addClass('panel-content')
			:attr('data-js-battle-royale', 'panel-content'):attr('id', 'panel0')
	local schedule = page:tag('div')
			:addClass('panel-content__collapsible')
			:addClass('is--collapsed')
			:attr('data-js-battle-royale', 'collapsible')
	local button = schedule:tag('h5')
			:addClass('panel-content__button')
			:attr('data-js-battle-royale', 'collapsible-button')
			:attr('tabindex', 0)
		button:tag('i')
				:addClass('far fa-chevron-up')
				:addClass('panel-content__button-icon')
		button:tag('span'):wikitext('Schedule')

	local scheduleList = schedule:tag('div')
			:addClass('panel-content__container')
			:attr('data-js-battle-royale', 'collapsible-container')
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
				:tag('div')
					:addClass('panel-content__game-schedule__container')
					:node(CustomMatchSummary._gameCountdown(game))
					:done()
	end)

	page:node(CustomMatchSummary._createPointsDistributionTable(match))

	return page:node(CustomMatchSummary._createMatchStandings(match))
end

---@param game table
---@param idx integer
---@return Html
function CustomMatchSummary._createGameTab(game, idx)
	local page = mw.html.create('div')
			:addClass('panel-content')
			:attr('data-js-battle-royale', 'panel-content')
			:attr('id', 'panel' .. idx)

	local gameDetails = page:tag('div')
			:addClass('panel-content__container')
			:attr('id', 'panelContent1')
			:attr('role', 'tabpanel')

	local informationList = gameDetails:tag('ul'):addClass('panel-content__game-schedule')
	informationList:tag('li')
			:tag('div')
					:addClass('panel-content__game-schedule__container')
					:tag('i')
							:addClass(CustomMatchSummary._countdownIcon(game))
							:addClass('panel-content__game-schedule__icon')
							:done()
					:node(CustomMatchSummary._gameCountdown(game))
	if game.map then
		informationList:tag('li')
				:tag('i')
						:addClass('far fa-map')
						:addClass('panel-content__game-schedule__icon')
						:done()
				:tag('span'):wikitext(Page.makeInternalLink(game.map))
	end

	page:node(CustomMatchSummary._createPointsDistributionTable(game))

	return page:node(CustomMatchSummary._createGameStandings(game))
end

---@param match table
---@return Html
function CustomMatchSummary._createMatchStandings(match)
	local wrapper = mw.html.create('div')
			:addClass('panel-table')
			:attr('data-js-battle-royale', 'table')

	local header = wrapper:tag('div')
			:addClass('panel-table__row')
			:addClass('row--header')
			:attr('data-js-battle-royale', 'header-row')

	if CustomMatchSummary._isFinished(match) then
		header:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--status')
	end

	Array.forEach(MATCH_STANDING_COLUMNS, function(column)
		local cell = header:tag('div')
				:addClass('panel-table__cell')
				:addClass(column.class)
		local groupedCell = cell:tag('div'):addClass('panel-table__cell-grouped')
				:tag('i')
						:addClass('panel-table__cell-icon')
						:addClass(column.iconClass)
						:done()
		local span = groupedCell:tag('span')
				:wikitext(column.header.value)
		if column.header.mobileValue then
				span:addClass('d-none d-md-block')
				groupedCell:tag('span')
						:wikitext(column.header.mobileValue)
						:addClass('d-block d-md-none')
		end
		span:done()
		if (column.sortable and column.sortType) then
			cell:attr('data-sort-type', column.sortType)
			groupedCell:tag('div')
				:addClass('panel-table__sort')
				:tag('i')
					:addClass('far fa-arrows-alt-v')
					:attr('data-js-battle-royale', 'sort-icon')
		end
	end)

	local gameCollectionContainerNavHolder = header:tag('div')
			:addClass('panel-table__cell')
			:addClass('cell--game-container-nav-holder')
			:attr('data-js-battle-royale', 'game-nav-holder')
	local gameCollectionContainer = gameCollectionContainerNavHolder:tag('div')
			:addClass('panel-table__cell')
			:addClass('cell--game-container')
			:attr('data-js-battle-royale', 'game-container')

	Array.forEach(match.games, function (game, idx)
		local gameContainer = gameCollectionContainer:tag('div')
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
						:node(CustomMatchSummary._gameCountdown(game))
						:done()

		local gameDetails = gameContainer:tag('div'):addClass('panel-table__cell__game-details')
		Array.forEach(MATCH_STANDING_COLUMNS.game, function(column)
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

	Array.forEach(match.opponents, function (opponentMatch, index)
		local row = wrapper:tag('div'):addClass('panel-table__row'):attr('data-js-battle-royale', 'row')

		if CustomMatchSummary._isFinished(match) then
			row:tag('div')
					:addClass('panel-table__cell')
					:addClass('cell--status')
					:addClass('bg-' .. (opponentMatch.advanceBg or ''))
					:node(CustomMatchSummary._getStatusIcon(opponentMatch.advanceBg))
		end

		Array.forEach(MATCH_STANDING_COLUMNS, function(column)
			local cell = row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(opponentMatch, index))
			if(column.sortVal and column.sortType) then
				cell:attr('data-sort-val', column.sortVal.value(opponentMatch, index)):attr('data-sort-type', column.sortType)
			end
		end)

		local gameRowContainer = row:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--game-container')
				:attr('data-js-battle-royale', 'game-container')

		Array.forEach(opponentMatch.games, function(opponent)
			local gameRow = gameRowContainer:tag('div'):addClass('panel-table__cell'):addClass('cell--game')

			Array.forEach(MATCH_STANDING_COLUMNS.game, function(column)
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

	Array.forEach(game.extradata.opponents, function (opponent, index)
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

	return mw.html.create('div'):addClass('match-countdown-block')
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
function CustomMatchSummary._getTrophy(place)
	if TROPHY_COLOR[place] then
		return 'fas fa-trophy', TROPHY_COLOR[place]
	end
end

---@param status string?
---@return string?
function CustomMatchSummary._getStatusIcon(status)
	if STATUS_ICONS[status] then
		return '<i class="' .. STATUS_ICONS[status] ..'"></i>'
	end
end

---@param opponent standardOpponent
---@return Html
function CustomMatchSummary._displayOpponent(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

return CustomMatchSummary
