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

function CustomMatchSummary._createOverallPage(match)
	local wrapper = mw.html.create('div'):addClass('panel-content'):attr('id', 'panel1')
	-- Schedule
	local schedule = wrapper:tag('h5'):addClass('panel-content__button'):attr('tabindex', 0):wikitext('Schedule')
	local timeList = wrapper:tag('div')
	timeList:addClass('panel-content__container'):attr('id', 'panelContent1'):attr('role', 'tabpanel')
	for idx, game in ipairs(match.games) do
		timeList:tag('div'):wikitext('Game ', idx, ': '):node(CustomMatchSummary._gameCountdown(game))
	end

	-- Help Text
	local scoring = match.extradata.scoring
	local helpText = wrapper:tag('h5'):addClass('panel-content__button'):addClass('is--collapsed'):attr('tabindex', 0):wikitext('Points Distribution')

	local pointsList = wrapper:tag('div')
	pointsList:addClass('panel-content__container'):addClass('is--hidden'):attr('id', 'panelContent1'):attr('role', 'tabpanel'):attr('hidden')
	pointsList:tag('div'):wikitext('1 kill ', Table.extract(scoring, 'kill'), ' kill point')
	local points = Table.groupBy(scoring, function (_, value)
		return value
	end)
	for point, placements in Table.iter.spairs(points, function (tbl, a, b)
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

function CustomMatchSummary._gameCountdown(game)
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
