---
-- @author Vogan for Liquipedia
--

local Arguments = require("Module:Arguments")
local Match = require("Module:Match")
local LocalMatch = require("Module:Brkts/WikiSpecific")
local Class = require('Module:Class')
local DivTable = require('Module:DivTable')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Links = require('Module:Links')
local Countdown = require('Module:Countdown')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local Template = require('Module:Template')

local BigMatch = Class.new()

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	local match = args[1]
	local tournament = {
		name = args.tournament,
		link = args.tournamentlink
	}

	if type(match) ~= 'string' then
		return ''
	end

	match = LocalMatch.processMatch(frame, match)
	local identifiers = BigMatch:_getId()
	match['bracketid'] = "MATCH_" .. identifiers[1]
	match['matchid'] = identifiers[2]
	Match.store(match)

	return BigMatch:render(frame, match, tournament)
end

function BigMatch:render(frame, match, tournament)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')

	local opponent1 = match['opponent1']
	local opponent2 = match['opponent2']

	local playerLookUp = self:_createPlayerLookUp(opponent1.match2players, opponent2.match2players)

	overall :node(self:header(match, opponent1, opponent2, tournament))
			:node(self:overview(match))
			:node(self:stats(frame, match, playerLookUp, {opponent1, opponent2}))
			:node(self:economy(match, opponent1, opponent2))

	return overall
end

function BigMatch:header(match, opponent1, opponent2, tournament)
	local teamLeft = self:_createTeamContainer('left', opponent1.name, opponent1.score, false)
	local teamRight = self:_createTeamContainer('right', opponent2.name, opponent2.score, false)

	local stream = Json.parse(match.stream or '{}')
	stream.date = mw.getContentLanguage():formatDate('r', match.date)
	stream.finished = Logic.readBool(match.finished) and 'true' or ''
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

	local ind = 1
	while match['map' .. ind] ~= nil do
		local map = match['map' .. ind]
		local didLeftWin = map.winner == 1
		local extradata = Json.parse(map.extradata or '')
		local scores = Json.parse(map.scores or '')
		local wasNotPlayed = map.resulttype == 'np'

		boxLeft :row(
			DivTable.Row()  :cell(mw.html.create('div'):wikitext((extradata.pick == '1') and 'Pick' or ''):addClass('map-pick'))
							:cell(mw.html.create('div'):wikitext(scores[1] or ''):addClass(didLeftWin and 'map-win' or 'map-lost'))
							:cell(mw.html.create('div'):wikitext('[[' .. map.map .. ']]'):addClass(wasNotPlayed and 'not-played' or ''))
							:cell(mw.html.create('div'):wikitext(scores[2] or ''):addClass((not didLeftWin) and 'map-win' or 'map-lost'))
							:cell(mw.html.create('div'):wikitext((extradata.pick == '2') and 'Pick' or ''):addClass('map-pick'))
		)

		ind = ind + 1
	end
	boxLeft = boxLeft:create()
	boxLeft:addClass('fb-match-page-box fb-match-page-box-left fb-match-page-map-scores')

	local boxRight = DivTable.create():setStriped(true)

	local stream = Json.parse(match.stream or "{}")
	local link = ''
	for key, value in pairs(stream) do
		link = link .. '[' .. Links.makeFullLink(key, value) .. ' <i class="lp-icon lp-' .. key .. '></i>] '
	end

	boxRight:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(link))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(match.date))
			)
			:row(
				DivTable.Row():cell(mw.html.create('div'):wikitext(match.patch or 'Placeholder patch'))
			)
	boxRight = boxRight:create()
	boxRight:addClass('fb-match-page-box')

	return mw.html.create('div'):addClass('fb-match-page-overview')
								:node(boxLeft)
								:node(boxRight)
end

function BigMatch:stats(frame, match, playerLookUp, opponents)
	local tabs = {
		This = 1,
	}
	tabs['hide-showall'] = true

	local ind = 1
	while match['map' .. ind] ~= nil do
		local map = match['map' .. ind]

		if map.resulttype == 'np' then
			break;
		end

		local extradata = Json.parse(map.extradata or {})

		tabs['name' .. ind] = 'Map ' .. ind

		local container = mw.html.create('div'):addClass('fb-match-page-valorant-stats')

		local participants = Json.parse(map.participants or '{}')
		if not Table.isEmpty(participants) then
			for i = 1, 2 do
				container:node(self:_createTeamStatsBanner(opponents[i].name, extradata['op1startside'], i == 1))

				local divTable = DivTable.create()
				divTable:row(
					DivTable.HeaderRow():cell(
							mw.html.create('div')	:wikitext('Player')
													:addClass('fb-match-page-valorant-stats-player')
						)
						:cell(mw.html.create('div'):wikitext('Agent'))
						:cell(mw.html.create('div'):wikitext('Kills'))
						:cell(mw.html.create('div'):wikitext('Deaths'))
						:cell(mw.html.create('div'):wikitext('Assists'))
						:cell(mw.html.create('div'):wikitext('ACS'))
				)

				for j = 1, 5 do

					local index = i .. '_' .. j
					local player = participants[index]

					local row = DivTable.Row()

					row	:cell(
							mw.html.create('div')	:addClass('fb-match-page-valorant-stats-player-name')
													:wikitext('[[' .. playerLookUp[index].name .. ']]')
						)
						:cell(
							mw.html.create('div')	:addClass('fb-match-page-valorant-stats-agent')
													:wikitext(Template.safeExpand(frame, 'AgentIcon/' .. player['agent']))
						)
						:cell(mw.html.create('div'):wikitext(player['kills']))
						:cell(mw.html.create('div'):wikitext(player['deaths']))
						:cell(mw.html.create('div'):wikitext(player['assists']))
						:cell(mw.html.create('div'):wikitext(player['acs']))
					divTable:row(row)
				end

				container:node(divTable:create():addClass('fb-match-page-valorant-stats-table'))
			end
		end

		tabs['content' .. ind] = tostring(container)

		ind = ind + 1
	end

	return Tabs.dynamic(tabs)
end

function BigMatch:economy(match, opponent1, opponent2)
	local tabs = {
		This = 1,
	}
	tabs['hide-showall'] = true

	local ind = 1

	while match['map' .. ind] ~= nil do
		local map = match['map' .. ind]

		if map.resulttype == 'np' or map.rounds == nil then
			break;
		end

		tabs['name' .. ind] = 'Map ' .. ind

		local data = {}
		for index, round in ipairs(map.rounds) do
			table.insert(data, {
				name = 'Round ' .. index,
				winby = round.winby,
				buy = round.buy,
				bank = round.bank,
				kills = round.kills,
			})
		end

		local chart = mw.ext.Charts.economytimeline({
			size = {
				height = 600,
				width = 800
			},
			colors = {'#B12A2A', '#1E7D7D'},
			groups = {opponent1.name, opponent2.name},
			data = data,
			markareas = {
				{ name = 'Eco', from = 0, to = 6000 },
				{ name = 'Semi-Eco', from = 6000, to = 14000 },
				{ name = 'Semi-Buy', from = 14000, to = 20000 },
				{ name = 'Full-Buy', from = 20000, to = 40000 },
			},
		})

		local chartContainer = mw.html.create('div'):addClass('fb-match-page-economy-timeline')
													:node(chart)

		tabs['content' .. ind] = tostring(chartContainer)

		ind = ind + 1
	end

	return Tabs.dynamic(tabs)
end

function BigMatch:_createTeamSeparator(format, stream)
	local countdown = mw.html.create('div')
		:addClass('fb-match-page-header-live')
		:wikitext(Countdown.create({date = stream.date, rawcountdown = true}))
	local divider = mw.html.create('div')
		:addClass('fb-match-page-header-divider')
		:wikitext(':')
	format = mw.html.create('div')
		:addClass('fb-match-page-header-format')
		:wikitext(format)
	return mw.html.create('div')
		:addClass('fb-match-page-header-separator')
		:node(countdown)
		:node(divider)
		:node(format)
end

function BigMatch:_createTeamStatsBanner(teamName, side, isFirstTeam)
	local banner = mw.html.create('div'):addClass('fb-match-page-valorant-stats-banner')
	local team = mw.html.create('div'):addClass('fb-match-page-valorant-stats-banner-team'):wikitext(teamName)
	local sideIndicator = mw.html.create('div')	:addClass('fb-match-page-valorant-stats-banner-side')
												:wikitext('Start Side: ')
	if side == 'atk' and isFirstTeam then
		sideIndicator:wikitext('Attack')
	elseif side == 'def' and isFirstTeam then
		sideIndicator:wikitext('Defence')
	elseif side == 'atk' and not isFirstTeam then
		sideIndicator:wikitext('Defence')
	elseif side == 'def' and not isFirstTeam then
		sideIndicator:wikitext('Attack')
	end

	return banner:node(team):node(sideIndicator)
end


function BigMatch:_createTeamContainer(side, teamName, score, hasWon)
	local link = '[[' .. teamName .. ']]'
	local team = mw.html.create('div')  :addClass('fb-match-page-header-team')
										:wikitext(mw.ext.TeamTemplate.teamicon(teamName) .. '<br/>' .. link)
	score = mw.html.create('div') :addClass('fb-match-page-header-score'):wikitext(score)

	local container = mw.html.create('div') :addClass('fb-match-page-header-team-container')
											:addClass('col-sm-4 col-xs-6 col-sm-pull-4')
	if side == 'left' then
		container:node(team):node(score)
	else
		container:node(score):node(team)
	end

	return container
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

function BigMatch:_createPlayerLookUp(opponent1Players, opponent2Players)
	local playerLookUp = {}

	for index, player in ipairs(opponent1Players) do
		playerLookUp['1_' .. index] = player
	end

	for index, player in ipairs(opponent2Players) do
		playerLookUp['2_' .. index] = player
	end

	return playerLookUp
end

return BigMatch
