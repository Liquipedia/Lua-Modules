---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local StarcraftMatchSummaryFfa = {}

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local TBD = 'TBD'
local UTC = Timezone.getTimezoneString('UTC')

local PHASE_ICONS = {
	finished = {iconName = 'concluded', color = 'icon--green'},
	ongoing = {iconName = 'live', color = 'icon--red'},
	upcoming = {iconName = 'upcomingandongoing'},
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
	advances = 'fas fa-chevron-double-up',
	eliminated = 'fas fa-skull',
}

local MATCH_STANDING_COLUMNS = {
	{
		class = 'cell--status',
		--iconClass = 'fas fa-hashtag',
		show = {
			value = function(match)
				return match.finished and #Array.filter(match.opponents, function(opponent)
					return Logic.readBool(opponent.advances)
				end) > 1
			end
		},
		row = {
			value = function (opponent, idx)
				local statusIcon = Logic.readBool(opponent.advances) and STATUS_ICONS.advances or STATUS_ICONS.eliminated
				return mw.html.create('i')
					:addClass(statusIcon)
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
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local worstPlace = opponent.extradata.worstPlace
				local icon, color = StarcraftMatchSummaryFfa._getTrophy(place)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-icon'):addClass(icon):addClass(color):done()
						:tag('span'):wikitext(StarcraftMatchSummaryFfa._displayRank(place, worstPlace)):done()
			end,
		},
	},
	{
		class = 'cell--team',
		iconClass = 'fas fa-users',
		header = {
			value = 'Participant',
		},
		row = {
			value = function (opponent, idx)
				return StarcraftMatchSummaryFfa._displayOpponent(opponent)
			end,
		},
	},
	{
		class = 'cell--total-points',
		iconClass = 'fas fa-star',
		header = {
			value = 'Total Points',
			mobileValue = 'Pts.',
		},
		show = {
			value = function(match)
				return not Logic.readBool(match.noScore)
			end
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.InlineScore(opponent)
			end,
		},
	},
	game = {
		{
			class = 'panel-table__cell__game-placement',
			iconClass = 'fas fa-trophy-alt',
			header = {
				value = 'Place',
				mobileValue = 'P.',
			},
			row = {
				class = function (opponent)
					return PLACEMENT_BG[opponent.placement]
				end,
				value = function (opponent)
					local placementDisplay
					if opponent.status and opponent.status ~= 'S' then
						placementDisplay = opponent.status or '-'
					else
						placementDisplay = StarcraftMatchSummaryFfa._displayRank(opponent.placement)
					end
					local icon, color = StarcraftMatchSummaryFfa._getTrophy(opponent.placement)
					return mw.html.create()
							:tag('i')
								:addClass('panel-table__cell-icon')
								:addClass(icon)
								:addClass(color)
								:done()
							:tag('span'):addClass('panel-table__cell-game__text')
									:wikitext(placementDisplay):done()
				end,
			},
		},
		{
			class = 'panel-table__cell__game-kills',
			iconClass = 'fas fa-star',
			show = {
				value = function(match)
					return not Logic.readBool(match.noScore)
				end
			},
			header = {
				value = 'Points',
				mobileValue = 'Pts.',
			},
			row = {
				value = function (opponent)
					return OpponentDisplay.InlineScore(Table.merge({extradata = {}, score = ''}, opponent))
				end,
			},
		},
	}
}

---@param props {match: StarcraftMatchGroupUtilMatch, bracketResetMatch: StarcraftMatchGroupUtilMatch?, config: table?}
---@return Html
function StarcraftMatchSummaryFfa.getByMatchId(props)
	local match = StarcraftMatchSummaryFfa._opponents(props.match)

	return StarcraftMatchSummaryFfa._createOverallPage(match)
end

function StarcraftMatchSummaryFfa._opponents(match)
	-- Add match opponent data to game opponent and the other way around
	Array.forEach(match.games, function (game, gameIndex)
		game.extradata.opponents = Array.map(game.opponents, function (opponent, opponentIdx)
			return {
				placement = opponent.placement,
				status = game.extradata['status' .. opponentIdx] or 'S',
				score = (game.scores or {})[opponentIdx],
			}
		end)
	end)

	Array.forEach(match.opponents, function (opponent, opponentIdx)
		opponent.games = Array.map(match.games, function (game)
			return game.extradata.opponents[opponentIdx]
		end)
	end)

	local placementSortFunction = function(opponent1, opponent2)
		local place1 = opponent1.placement or math.huge
		local place2 = opponent2.placement or math.huge
		if place1 ~= place2 then
			return place1 < place2
		end
		if opponent1.status ~= 'S' and opponent2.status == 'S' then
			return false
		end
		if opponent2.status ~= 'S' and opponent1.status == 'S' then
			return true
		end
		if opponent1.score and opponent2.score and opponent1.score ~= opponent2.score then
			return opponent1.score > opponent2.score
		end
		return (opponent1.name or ''):lower() < (opponent2.name or ''):lower()
	end

	-- Sort match level based on placement
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, placementSortFunction)

	if not match.finished then
		return match
	end
	local cache = {
		index = #match.opponents,
		currentWorst = #match.opponents
	}
	Array.forEach(Array.reverse(match.opponents), function(opponent)
		local place = opponent.placement
		opponent.extradata.worstPlace = cache.currentWorst
		if place == cache.index then
			cache.currentWorst = place - 1
		end
		cache.index = cache.index - 1
	end)

	return match
end

---@param match table
---@return Html
function StarcraftMatchSummaryFfa._createOverallPage(match)
	local page = mw.html.create('div')
			:addClass('panel-content')
			:attr('data-js-battle-royale', 'panel-content'):attr('id', 'panel0')

	local schedule = page:tag('div')

	local scheduleList = schedule:tag('div')
			:addClass('panel-content__container')
			:attr('role', 'tabpanel')
			:tag('ul')
					:addClass('panel-content__game-schedule')

	scheduleList:tag('li')
			:node(StarcraftMatchSummaryFfa._countdownIcon(match, 'panel-content__game-schedule__icon'))
			:tag('span')
					:addClass('panel-content__game-schedule__title')
					:wikitext('Match:')
					:done()
			:tag('div')
				:addClass('panel-content__game-schedule__container')
				:node(StarcraftMatchSummaryFfa._countdown(match))

	return page:node(StarcraftMatchSummaryFfa._createMatchStandings(match))
end


---@param match table
---@return Html
function StarcraftMatchSummaryFfa._createMatchStandings(match)
	local wrapper = mw.html.create('div')
			:addClass('panel-table')
			:attr('data-js-battle-royale', 'table')

	local header = wrapper:tag('div')
			:addClass('panel-table__row')
			:addClass('row--header')
			:attr('data-js-battle-royale', 'header-row')

	Array.forEach(MATCH_STANDING_COLUMNS, function(column)
		if column.show and not column.show.value(match) then
			return
		end

		local cell = header:tag('div')
				:addClass('panel-table__cell')
				:addClass(column.class)
		local groupedCell = cell:tag('div'):addClass('panel-table__cell-grouped')
				:tag('i')
						:addClass('panel-table__cell-icon')
						:addClass(column.iconClass)
						:done()
		local span = groupedCell:tag('span')
				:wikitext((column.header or {}).value)
		if (column.header or {}).mobileValue then
				span:addClass('d-none d-md-block')
				groupedCell:tag('span')
						:wikitext((column.header or {}).mobileValue)
						:addClass('d-block d-md-none')
		end
		span:done()
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
				:css('text-align', 'left')
				:tag('div')
						:addClass('panel-table__cell__game-title')
						:css('justify-content', 'flex-start')
						:node(StarcraftMatchSummaryFfa._countdownIcon(game, 'panel-table__cell-icon'))
						:tag('span')
								:addClass('panel-table__cell-text')
								:wikitext('Game ', idx)
								:done()
						:done()
						:node(StarcraftMatchSummaryFfa._countdown(game))
						:node(StarcraftMatchSummaryFfa._map(game))
						:done()

		local gameDetails = gameContainer:tag('div'):addClass('panel-table__cell__game-details')
		Array.forEach(MATCH_STANDING_COLUMNS.game, function(column)
			if column.show and not column.show.value(match) then
				return
			end
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

		Array.forEach(MATCH_STANDING_COLUMNS, function(column)
			if column.show and not column.show.value(match) then
				return
			end

			local cell = row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(opponentMatch, index))
		end)

		local gameRowContainer = row:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--game-container')
				:attr('data-js-battle-royale', 'game-container')

		Array.forEach(opponentMatch.games, function(opponent)
			local gameRow = gameRowContainer:tag('div'):addClass('panel-table__cell'):addClass('cell--game')

			Array.forEach(MATCH_STANDING_COLUMNS.game, function(column)
				if column.show and not column.show.value(match) then
					return
				end
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
function StarcraftMatchSummaryFfa._map(game)
	return mw.html.create()
		:tag('i')
			:addClass('far fa-map')
			:addClass('panel-content__game-schedule__icon')
			:done()
		:node(DisplayHelper.MapAndStatus(game, {noLink = (game.map or ''):upper() == TBD}))
end

---@param game table
---@return boolean
function StarcraftMatchSummaryFfa._isFinished(game)
	return game.winner ~= nil
end

---@param game table
---@param additionalClass string
---@return string?
function StarcraftMatchSummaryFfa._countdownIcon(game, additionalClass)
	local iconData = PHASE_ICONS[MatchGroupUtil.computeMatchPhase(game)] or {}
	return Icon.makeIcon{iconName = iconData.iconName, color = iconData.color, additionalClasses = {additionalClass}}
end

---Creates a countdown block for a given game
---Attaches any VODs of the game as well
---@param game table
---@return Html?
function StarcraftMatchSummaryFfa._countdown(game)
	if not game.extradata.timezoneid then
		return
	end

	local timestamp = Date.readTimestamp(game.date) + (Timezone.getOffset(game.extradata.timezoneid) or 0)
	local dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
			.. (Timezone.getTimezoneString(game.extradata.timezoneid) or UTC)

	local stream = Table.merge(game.stream, {
		date = dateString,
		finished = StarcraftMatchSummaryFfa._isFinished(game) and 'true' or nil,
	})

	return mw.html.create('div'):addClass('match-countdown-block')
			:node(require('Module:Countdown')._create(stream))
			:node(game.vod and VodLink.display{vod = game.vod} or nil)
end

---@param placementStart string|number|nil
---@param placementEnd string|number|nil
---@return string
function StarcraftMatchSummaryFfa._displayRank(placementStart, placementEnd)
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
function StarcraftMatchSummaryFfa._getTrophy(place)
	if TROPHY_COLOR[place] then
		return 'fas fa-trophy', TROPHY_COLOR[place]
	end
end

---@param opponent standardOpponent
---@return Html
function StarcraftMatchSummaryFfa._displayOpponent(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

return StarcraftMatchSummaryFfa
