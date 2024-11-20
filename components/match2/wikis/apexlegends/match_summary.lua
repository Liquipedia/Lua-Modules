---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:Summary/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class ApexMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games ApexMatchGroupUtilGame[]

local PLACEMENT_BG = {
	'cell--gold',
	'cell--silver',
	'cell--bronze',
	'cell--copper',
}

local STATUS_ICONS = {
	-- Normal Status
	up = 'fas fa-chevron-double-up',
	stayup = 'fas fa-chevron-up',
	stay = 'fas fa-equals',
	staydown = 'fas fa-chevron-down',
	down = 'fas fa-skull',

	-- Special Status for Match Point matches
	trophy = 'fas fa-trophy',
	matchpoint = 'fad fa-diamond',
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
				local icon, color = SummaryHelper.getTrophy(place)
				return mw.html.create()
						:tag('i'):addClass('panel-table__cell-icon'):addClass(icon):addClass(color):done()
						:tag('span'):wikitext(SummaryHelper.displayRank(place)):done()
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
				return OpponentDisplay.InlineScore(opponent)
			end,
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.InlineScore(opponent)
			end,
		},
	},
	{
		sortable = true,
		sortType = 'match-points',
		class = 'cell--match-points',
		iconClass = 'fad fa-diamond',
		show = {
			value = function(match)
				return match.matchPointThreadhold
			end
		},
		header = {
			value = 'MPe Game',
			mobileValue = 'MPe',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.matchPointReachedIn or 999 -- High number that should not be exceeded
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.matchPointReachedIn and "Game " .. opponent.matchPointReachedIn or nil
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
					local placementDisplay
					if opponent.status and opponent.status ~= 'S' then
						placementDisplay = '-'
					else
						placementDisplay = SummaryHelper.displayRank(opponent.placement)
					end
					local icon, color = SummaryHelper.getTrophy(opponent.placement)
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

---@param props {bracketId: string, matchId: string}
---@return string
function CustomMatchSummary.getByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	match.matchPointThreadhold = Table.extract(match.extradata.scoring, 'matchPointThreadhold')
	CustomMatchSummary._opponents(match)

	local matchSummary = mw.html.create()

	local addNode = FnUtil.curry(matchSummary.node, matchSummary)
	addNode(CustomMatchSummary._createHeader(match))
	addNode(CustomMatchSummary._createOverallPage(match))

	return tostring(matchSummary)
end

function CustomMatchSummary._opponents(match)
	-- Add games opponent data to the match opponent
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.opponents[idx]
		end)
	end)

	if match.matchPointThreadhold then
		Array.forEach(match.opponents, function(opponent)
			local matchPointReachedIn
			local sum = opponent.extradata.startingpoints or 0
			for gameIdx, game in ipairs(opponent.games) do
				if sum >= match.matchPointThreadhold then
					matchPointReachedIn = gameIdx
					break
				end
				sum = sum + (game.score or 0)
			end
			opponent.matchPointReachedIn = matchPointReachedIn
		end)
	end

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)
end

---@param match table
---@return Html
function CustomMatchSummary._createHeader(match)
	local function createHeader(title, icon, idx)
		return mw.html.create('li')
				:addClass('panel-tabs__list-item')
				:attr('data-js-battle-royale', 'panel-tab')
				:attr('data-js-battle-royale-content-target-id', match.matchId .. 'panel' .. idx)
				:attr('data-js-battle-royale-game-idx', idx)
				:attr('role', 'tab')
				:attr('tabindex', 0)
				:node(icon)
				:tag('h4'):addClass('panel-tabs__title'):wikitext(title):done()
	end
	local standingsIcon = Icon.makeIcon{iconName = 'standings', additionalClasses = {'panel-tabs__list-icon'}}
	local header = mw.html.create('ul')
			:addClass('panel-tabs__list')
			:attr('role', 'tablist')
			:node(createHeader('Overall standings', standingsIcon, 0))

	Array.forEach(match.games, function (game, idx)
		header:node(createHeader('Game '.. idx, SummaryHelper.countdownIcon(game, 'panel-tabs__list-icon'), idx))
	end)

	return mw.html.create('div')
			:addClass('panel-tabs')
			:attr('role', 'tabpanel')
			:node(header)
end

---@param match table
---@return Html
function CustomMatchSummary._createOverallPage(match)
	local page = mw.html.create('div')
			:addClass('panel-content')
			:attr('data-js-battle-royale', 'panel-content')
			:attr('id', match.matchId .. 'panel0')
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
				:node(SummaryHelper.countdownIcon(game, 'panel-content__game-schedule__icon'))
				:tag('span')
						:addClass('panel-content__game-schedule__title')
						:wikitext('Game ', idx, ':')
						:done()
				:tag('div')
					:addClass('panel-content__game-schedule__container')
					:node(SummaryHelper.gameCountdown(game))
					:done()
	end)

	page:node(SummaryHelper.createPointsDistributionTable(SummaryHelper.createScoringData(match)))

	return page:node(CustomMatchSummary._createMatchStandings(match))
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

	if CustomMatchSummary._showStatusColumn(match) then
		header:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--status')
	end

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
						:node(SummaryHelper.countdownIcon(game, 'panel-table__cell-icon'))
						:tag('span')
								:addClass('panel-table__cell-text')
								:wikitext('Game ', idx)
								:done()
						:done()
						:node(SummaryHelper.gameCountdown(game))
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

	Array.forEach(match.opponents, function (matchOpponent, index)
		local row = wrapper:tag('div'):addClass('panel-table__row'):attr('data-js-battle-royale', 'row')

		if CustomMatchSummary._showStatusColumn(match) then
			row:tag('div')
					:addClass('panel-table__cell')
					:addClass('cell--status')
					:addClass('bg-' .. (matchOpponent.advanceBg or ''))
					:node(CustomMatchSummary._getStatusIcon(match.extradata.status[index]))
		end

		Array.forEach(MATCH_STANDING_COLUMNS, function(column)
			if column.show and not column.show.value(match) then
				return
			end

			local cell = row:tag('div')
					:addClass('panel-table__cell')
					:addClass(column.class)
					:node(column.row.value(matchOpponent, index))
			if(column.sortVal and column.sortType) then
				cell:attr('data-sort-val', column.sortVal.value(matchOpponent, index)):attr('data-sort-type', column.sortType)
			end
		end)

		local gameRowContainer = row:tag('div')
				:addClass('panel-table__cell')
				:addClass('cell--game-container')
				:attr('data-js-battle-royale', 'game-container')

		Array.forEach(matchOpponent.games, function(opponent)
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

---@param status string?
---@return string?
function CustomMatchSummary._getStatusIcon(status)
	if STATUS_ICONS[status] then
		return '<i class="' .. STATUS_ICONS[status] ..'"></i>'
	end
end

---Determines whether the status column should be shown or not
---@param match table
---@return boolean
function CustomMatchSummary._showStatusColumn(match)
	return Table.isNotEmpty(match.extradata.status)
end

return CustomMatchSummary
