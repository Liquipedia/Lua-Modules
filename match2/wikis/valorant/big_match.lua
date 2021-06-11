---
-- @author Vogan for Liquipedia
--

local Arguments = require("Module:Arguments")
local Json = require("Module:Json")
local Match = require("Module:Match")
local LocalMatch = require("Module:Brkts/WikiSpecific")
local Class = require('Module:Class')
local Template = require('Module:Template')
local LuaUtils = require('Module:LuaUtils')
local DivTable = require('Module:DivTable')
local Links = require('Module:Links')
local Countdown = require('Module:Countdown')

local BigMatch = Class.new()

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	local match = args[1]

	if type(match) ~= 'string' then
		return ''
	end

	match = LocalMatch.processMatch(frame, match)
	local identifiers = BigMatch:_getId()
	match['bracketid'] = "MATCH_" .. identifiers[1]
	match['matchid'] = identifiers[2]
	Match.store(match)

	local tournament = {
		name = args.tournament or '',
		link = args.tournamentlink or ''
	}
	return BigMatch:render(frame, match, tournament)
end

function BigMatch:render(frame, match, tournament)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')

	local opponent1 = match['opponent1']
	local opponent2 = match['opponent2']

	overall :node(self:header(match, opponent1, opponent2, tournament))
			:node(self:overview(match))
			:node(self:stats(frame, opponent1, opponent2))
	return overall
end

function BigMatch:header(match, opponent1, opponent2, tournament)
	local teamLeft = self:_createTeamContainer('left', opponent1.name, opponent1.score, false)
	local teamRight = self:_createTeamContainer('right', opponent2.name, opponent2.score, false)

	local stream = Json.parse(match.stream or '{}')
	stream.date = mw.getContentLanguage():formatDate('r', match.date)
	stream.finished = LuaUtils.misc.readBool(match.finished) and 'true' or ''
	local divider = self:_createTeamSeparator(match.format, stream)

	local teamsRow = mw.html.create('div'):addClass('fb-match-page-header-teams row')
											:node(teamLeft)
											:node(divider)
											:node(teamRight)
	local tournamentRow = mw.html.create('div') :addClass('fb-match-page-header-tournament')
												:wikitext('[[' .. tournament.link .. '|' .. tournament.name .. ']]')
	return mw.html.create('div'):addClass("fb-match-page-header")
								:node(tournamentRow)
								:node(teamsRow)
end

function BigMatch:overview(match)
	local boxLeft = DivTable.create():setStriped(true)

	boxLeft:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext("'''Referee: '''" .. (match.referee or '')))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext("'''MVP: '''" .. (match.mvp or '')))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext("'''Attendance: '''" .. (match.attendance or '')))
			)

	boxLeft = boxLeft:create()
	boxLeft:addClass('fb-match-page-box fb-match-page-box-left fb-match-page-map-scores')

	local boxRight = DivTable.create():setStriped(true)

	local stream = Json.parse(match.stream or "{}")
	local link = ''
	for key, value in pairs(stream) do
		link = link .. '[' .. Links.makeFullLink(key, value) .. ' <i class="lp-icon lp-' .. key .. '></i>] '
	end

	if link == '' then
		link = 'No streams found!'
	end

	boxRight:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(link))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(match.date))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(match.venue or 'Some venue'))
			)
	boxRight = boxRight:create()
	boxRight:addClass('fb-match-page-box')

	return mw.html.create('div'):addClass('fb-match-page-overview')
								:node(boxLeft)
								:node(boxRight)
end

function BigMatch:stats(frame, opponent1, opponent2)
	local center = mw.html.create('center'):css('margin-top', '32px')

	local opponent1Stats = Json.parse(opponent1.extradata)
	local opponent2Stats = Json.parse(opponent2.extradata)
	return center:node(Template.safeExpand(frame, 'MatchStats', {
		team1 = opponent1.name,
		goals1 = self:_parseStatsItem(opponent1Stats.goals),
		tshots1 = self:_parseStatsItem(opponent1Stats.shots),
		sotarget1 = self:_parseStatsItem(opponent1Stats.shotsot),
		saves1 = self:_parseStatsItem(opponent1Stats.saves),
		corners1 = self:_parseStatsItem(opponent1Stats.corners),
		fouls1 = self:_parseStatsItem(opponent1Stats.fouls),
		offside1 = self:_parseStatsItem(opponent1Stats.offsides),
		yellow1 = self:_parseStatsItem(opponent1Stats.yellows),
		red1 = self:_parseStatsItem(opponent1Stats.reds),
		team2 = opponent2.name,
		goals2 = self:_parseStatsItem(opponent2Stats.goals),
		tshots2 = self:_parseStatsItem(opponent2Stats.shots),
		sotarget2 = self:_parseStatsItem(opponent2Stats.shotsot),
		saves2 = self:_parseStatsItem(opponent2Stats.saves),
		corners2 = self:_parseStatsItem(opponent2Stats.corners),
		fouls2 = self:_parseStatsItem(opponent2Stats.fouls),
		offside2 = self:_parseStatsItem(opponent2Stats.offsides),
		yellow2 = self:_parseStatsItem(opponent2Stats.yellows),
		red2 = self:_parseStatsItem(opponent2Stats.reds),
	}))
end

function BigMatch:_createTeamSeparator(format, stream)
	local countdown = mw.html.create('div') :addClass('fb-match-page-header-live')
						:wikitext(Countdown.create({date = stream.date, rawcountdown = true}))
	local divider = mw.html.create('div')   :addClass('fb-match-page-header-divider')
						:wikitext(':')
	local formatNode = mw.html.create('div'):addClass('fb-match-page-header-format')
						:wikitext(format)
	return mw.html.create('div'):addClass('fb-match-page-header-separator')
								:node(countdown)
								:node(divider)
								:node(formatNode)
end

function BigMatch:_createTeamContainer(side, teamName, score, hasWon)
	local link = '[[' .. teamName .. ']]'
	local team = mw.html.create('div')  :addClass('fb-match-page-header-team')
										:wikitext(mw.ext.TeamTemplate.teamicon(teamName) .. '<br/>' .. link)
	local scoreNode = mw.html.create('div') :addClass('fb-match-page-header-score'):wikitext(score)

	local container = mw.html.create('div') :addClass('fb-match-page-header-team-container')
											:addClass('col-sm-4 col-xs-6 col-sm-pull-4')
	if side == 'left' then
		container:node(team):node(scoreNode)
	else
		container:node(score):node(team)
	end

	return container
end

function BigMatch:_parseStatsItem(item)
	if item == nil or tonumber(item) ~= nil then
		return item
	end

	local parsedItem = Json.parse(item)

	local count = 0

	while parsedItem['t' .. count + 1] ~= nil do
		count = count + 1
	end

	return count
end

function BigMatch:_getId()
	local title = mw.title.getCurrentTitle()

	-- Match alphanumeric pattern 10 characters long, followed by space and then the match id
	local staticId = string.match(title.text, '%w%w%w%w%w%w%w%w%w%w .*')
	local fullBracketId = string.match(title.text, '%w%w%w%w%w%w%w%w%w%w')
	local matchId = string.sub(staticId, 12)

	return {fullBracketId, matchId}
end

function BigMatch:_formatDate(date)
	return mw.getContentLanguage():formatDate('r', date)
end

return BigMatch
