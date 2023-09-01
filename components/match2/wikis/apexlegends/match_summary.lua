---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init('420px')
	matchSummary.root:addClass('brkts-popup brkts-match-info-flat')

	matchSummary.headerElement = CustomMatchSummary._createHeader(match)
	matchSummary.bodyElement = CustomMatchSummary._createOverallPage(match)

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local function createHeader(title)
		return mw.html.create('div'):addClass('match-header-item'):wikitext(title)
	end
	local header = mw.html.create('div')
	header:node(createHeader('Overall Standings'))

	for idx in ipairs(match.games) do
		header:node('Game '.. idx)
	end

	return header
end

function CustomMatchSummary._createOverallPage(match)
	local wrapper = mw.html.create('div')
	-- Schedule
	local schedule = mw.html.create('div')
	schedule:wikitext('Schedule')
	for idx, game in ipairs(match.games) do
		schedule:tag('div'):wikitext('Game ', idx, ': '):node(CustomMatchSummary._gameCountdown(game))
	end

	-- Help Text
	local helpText = mw.html.create('div')
	helpText:wikitext('Points Distribution')
	helpText:wikitext('blablabla')

	return wrapper:node(schedule):node(helpText)
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
