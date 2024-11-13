---
-- @Liquipedia
-- wiki=Summary/Util
-- page=Module:GameSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local VodLink = require('Module:VodLink')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local CustomSummaryHelper = {}
CustomSummaryHelper.NO_PLACEMENT = -99

local PHASE_ICONS = {
	finished = {iconName = 'concluded', color = 'icon--green'},
	ongoing = {iconName = 'live', color = 'icon--red'},
	upcoming = {iconName = 'upcomingandongoing'},
}

local TROPHY_COLOR = {
	'icon--gold',
	'icon--silver',
	'icon--bronze',
	'icon--copper',
}

---@param opponent standardOpponent
---@return Html
function CustomSummaryHelper.displayOpponent(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

---@param place integer
---@return string? icon
---@return string? iconColor
function CustomSummaryHelper.getTrophy(place)
	if TROPHY_COLOR[place] then
		return 'fas fa-trophy', TROPHY_COLOR[place]
	end
end

---Creates a countdown block for a given game
---Attaches any VODs of the game as well
---@param game table
---@return Html?
function CustomSummaryHelper.gameCountdown(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return
	end
	-- TODO Use local TZ
	local dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' ' .. Timezone.getTimezoneString('UTC')

	local stream = Table.merge(game.stream, {
		date = dateString,
		finished = CustomSummaryHelper.isFinished(game) and 'true' or nil,
	})

	return mw.html.create('div'):addClass('match-countdown-block')
			:node(require('Module:Countdown')._create(stream))
			:node(game.vod and VodLink.display{vod = game.vod} or nil)
end

---@param game table
---@return boolean
function CustomSummaryHelper.isFinished(game)
	return game.winner ~= nil
end

---@param game table
---@return string?
function CustomSummaryHelper.countdownIcon(game, additionalClass)
	local iconData = PHASE_ICONS[MatchGroupUtil.computeMatchPhase(game)] or {}
	return Icon.makeIcon{iconName = iconData.iconName, color = iconData.color, additionalClasses = {additionalClass}}
end

---@param placementStart string|number|nil
---@param placementEnd string|number|nil
---@return string
function CustomSummaryHelper.displayRank(placementStart, placementEnd)
	if CustomSummaryHelper.NO_PLACEMENT == placementStart then
		return '-'
	end

	local places = {}

	if placementStart then
		table.insert(places, Ordinal.toOrdinal(placementStart))
	end

	if placementStart and placementEnd and placementEnd > placementStart then
		table.insert(places, Ordinal.toOrdinal(placementEnd))
	end

	return table.concat(places, ' - ')
end

---@param scoringTable table
---@return Html
function CustomSummaryHelper.createPointsDistributionTable(scoringTable)
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

	pointsList:node(createItem('fas fa-skull', nil, '1 kill', scoringTable.kill, 'kill'))

	Array.forEach(scoringTable.placement, function (slot)
		local title = CustomSummaryHelper.displayRank(slot.rangeStart, slot.rangeEnd)
		local icon, iconColor = CustomSummaryHelper.getTrophy(slot.rangeStart)

		pointsList:node(createItem(icon, iconColor, title, slot.score, 'placement'))
	end)

	return wrapper
end

---@param opponent1 table
---@param opponent2 table
---@return boolean
function CustomSummaryHelper.placementSortFunction(opponent1, opponent2)
	if opponent1.placement and opponent2.placement and opponent1.placement ~= opponent2.placement then
		return opponent1.placement < opponent2.placement
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
	return (opponent1.name or '') < (opponent2.name or '')
end

---@param match table
---@return {kill: number, placement: {rangeStart: integer, rangeEnd: integer, score:number}[]}
function CustomSummaryHelper.createScoringData(match)
	local scoreSettings = match.extradata.scoring

	local scorePlacement = {}

	local points = Table.groupBy(scoreSettings.placement, function (_, value)
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
		kill = scoreSettings.kill,
		placement = scorePlacement,
		matchPointThreadhold = scoreSettings.matchPointThreadhold,
	}
end

return CustomSummaryHelper
