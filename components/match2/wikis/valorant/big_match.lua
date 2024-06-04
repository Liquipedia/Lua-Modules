---
-- @Liquipedia
-- wiki=valorant
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DivTable = require('Module:DivTable')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Links = require('Module:Links')
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom')

local BigMatch = Class.new()

local ROUND_ONE = 1
local ROUNDS_PER_HALF = 12
local COLOR_FIRST_TEAM = '#B12A2A'
local COLOR_SECOND_TEAM = '#1E7D7D'

---@param frame Frame
---@return Html
function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)
	local bigMatch = BigMatch()

	local match = Json.parseIfString(args[1])
	assert(type(match) == 'table')

	match = CustomMatchGroupInput.processMatch(match, {isStandalone = true})

	local identifiers = bigMatch:_getId()
	match['bracketid'] = 'MATCH_' .. identifiers[1]
	match['matchid'] = identifiers[2]
	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false})

	-- Attempty to automatically retrieve tournament link from the bracket
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = bigMatch:_fetchTournamentLinkFromMatch(identifiers)
	end

	local tournamentData = bigMatch:_fetchTournamentInfo(args.tournamentlink)

	match.patch = match.patch or tournamentData.patch
	local tournament = {
		name = args.tournament or tournamentData.name,
		link = args.tournamentlink or tournamentData.pagename,
	}

	return bigMatch:render(match, tournament)
end

---@param match table
---@param tournament {name: string?, link: string?}
---@return Html
function BigMatch:render(match, tournament)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')

	local opponent1 = match.match2opponents[1]
	local opponent2 = match.match2opponents[2]

	local playerLookUp = self:_createPlayerLookUp(opponent1.match2players, opponent2.match2players)

	local tabs = {This = 1, ['hide-showall'] = true}
	tabs.name1 = 'Player Stats'
	tabs.content1 = self:stats(match, playerLookUp, {opponent1, opponent2})
	tabs.name2 = 'Economy'
	tabs.content2 = self:economy(match, opponent1, opponent2)

	overall :node(self:header(match, opponent1, opponent2, tournament))
			:node(self:overview(match))
			:node(Tabs.dynamic(tabs))

	return overall
end

---@param match table
---@param opponent1 table
---@param opponent2 table
---@param tournament {name: string?, link: string?}
---@return Html
function BigMatch:header(match, opponent1, opponent2, tournament)
	local teamLeft = self:_createTeamContainer('left', opponent1.name, opponent1.score, false)
	local teamRight = self:_createTeamContainer('right', opponent2.name, opponent2.score, false)

	local divider = self:_createTeamSeparator(match.format, match)

	local teamsRow = mw.html.create('div'):addClass('fb-match-page-header-teams row')
											:node(teamLeft)
											:node(divider)
											:node(teamRight)
	local tournamentRow = mw.html.create('div'):addClass('fb-match-page-header-tournament')
	if tournament.link and tournament.name then
		tournamentRow:wikitext('[[' .. tournament.link .. '|' .. tournament.name .. ']]')
	end
	return mw.html.create('div'):addClass('fb-match-page-header')
								:node(tournamentRow)
								:node(teamsRow)
end

---@param match table
---@return Html
function BigMatch:overview(match)
	local boxLeft = DivTable.create():setStriped(true)

	local ind = 1
	while match.match2games[ind] ~= nil do
		local map = match.match2games[ind]
		local didLeftWin = map.winner == 1
		local extradata = map.extradata
		local scores = map.scores
		local wasNotPlayed = map.resulttype == 'np'

		boxLeft :row(
			DivTable.Row()	:cell(mw.html.create('div'):wikitext((extradata.pick == '1') and 'Pick' or ''):addClass('map-pick'))
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

	local stream = match.stream
	local link = ''
	for key, value in pairs(stream) do
		link = link .. '[' .. Links.makeFullLink(key, value) .. ' <i class="lp-icon lp-' .. key .. '></i>] '
	end

	boxRight
		:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(link))
		)
		:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(
				Countdown.create{
					rawdatetime = true,
					finished = match.finished,
					date = match.date .. '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
				}
			))
		)
		:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(match.patch and 'Patch ' .. match.patch))
		)
	boxRight = boxRight:create()
	boxRight:addClass('fb-match-page-box')

	return mw.html.create('div'):addClass('fb-match-page-overview')
		:node(boxLeft)
		:node(boxRight)
end

---@param match table
---@param playerLookUp table<string, table>
---@param opponents table[]
---@return (string|Html)?
function BigMatch:stats(match, playerLookUp, opponents)
	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	local ind = 1
	while match.match2games[ind] ~= nil do
		local map = match.match2games[ind]

		if map.resulttype == 'np' then
			break;
		end

		local extradata = map.extradata

		tabs['name' .. ind] = 'Map ' .. ind

		local container = mw.html.create('div'):addClass('fb-match-page-valorant-stats')

		local participants = map.participants
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
													:wikitext(CharacterIcon.Icon{
														character = player['agent'],
														size = '20px'
													})
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

---@param match table
---@param opponent1 table
---@param opponent2 table
---@return (string|Html)?
function BigMatch:economy(match, opponent1, opponent2)
	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	local ind = 1
	while match.match2games[ind] ~= nil do
		local map = match.match2games[ind]

		if map.resulttype == 'np' or map.rounds == nil then
			break;
		end

		tabs['name' .. ind] = 'Map ' .. ind

		local chart = ''
		local data
		-- First half
		data = self:_processHalf(map, ROUND_ONE, math.min(#map.rounds, ROUNDS_PER_HALF))
		if #data > 0 then
			chart = chart .. self:_createChart(data, {opponent1, opponent2},{COLOR_FIRST_TEAM, COLOR_SECOND_TEAM})
		end

		-- Second half
		data = self:_processHalf(map, ROUND_ONE+ROUNDS_PER_HALF, math.min(#map.rounds, ROUNDS_PER_HALF*2))
		if #data > 0 then
			chart = chart .. self:_createChart(data, {opponent1, opponent2},{COLOR_SECOND_TEAM, COLOR_FIRST_TEAM})
		end

		-- OT
		data = self:_processHalf(map, ROUND_ONE+ROUNDS_PER_HALF*2, #map.rounds)
		if #data > 0 then
			chart = chart .. self:_createChart(data, {opponent1, opponent2},{COLOR_FIRST_TEAM, COLOR_SECOND_TEAM})
		end

		local chartContainer = mw.html.create('div'):addClass('fb-match-page-economy-timeline')
			:node(chart)

		tabs['content' .. ind] = tostring(chartContainer)

		ind = ind + 1
	end

	return Tabs.dynamic(tabs)
end

---@param map table
---@param startRound integer
---@param endRound integer
---@return table
function BigMatch:_processHalf(map, startRound, endRound)
	local roundData = {}
	for round = startRound, endRound do
		table.insert(roundData, self:_processRound(map, round))
	end
	return roundData
end

---@param map table
---@param roundIndex integer
---@return table
function BigMatch:_processRound(map, roundIndex)
	local round = map.rounds[roundIndex]

	return {
		name = 'Round ' .. roundIndex,
		winby = round.winby,
		buy = round.buy,
		bank = round.bank,
		kills = round.kills,
	}
end

---@param data table
---@param opponents table[]
---@param colors string[]
---@return unknown
function BigMatch:_createChart(data, opponents, colors)
	return mw.ext.Charts.economytimeline({
		size = {
			height = 600,
			width = 800
		},
		colors = colors,
		groups = {opponents[1].name, opponents[2].name},
		data = data,
		markareas = {
			{ name = 'Eco', from = 0, to = 6000 },
			{ name = 'Semi-Eco', from = 6000, to = 14000 },
			{ name = 'Semi-Buy', from = 14000, to = 20000 },
			{ name = 'Full-Buy', from = 20000, to = 40000 },
		},
	})
end

---@param format string?
---@param match table
---@return Html
function BigMatch:_createTeamSeparator(format, match)
	local countdown = mw.html.create('div')
		:addClass('fb-match-page-header-live')
		:css('font-weight', 'bold')
		:wikitext(Countdown.create{
			date = match.date .. '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>',
			finished = Logic.readBool(match.finished) and 'true' or '',
			rawcountdown = true,
		})
	local divider = mw.html.create('div')
		:addClass('fb-match-page-header-divider')
		:wikitext(':')
	local formatDisplay = mw.html.create('div')
		:addClass('fb-match-page-header-format')
		:wikitext(format)
	return mw.html.create('div')
		:addClass('fb-match-page-header-separator')
		:node(countdown)
		:node(divider)
		:node(formatDisplay)
end

---@param teamName string?
---@param side string?
---@param isFirstTeam boolean
---@return Html
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

---@param side string
---@param teamName string
---@param score integer|string?
---@param hasWon boolean?
---@return Html
function BigMatch:_createTeamContainer(side, teamName, score, hasWon)
	local link = '[[' .. teamName .. ']]'
	local team = mw.html.create('div')	:addClass('fb-match-page-header-team')
										:wikitext(mw.ext.TeamTemplate.teamicon(teamName) .. '<br/>' .. link)
	local scoreDisplay = mw.html.create('div'):addClass('fb-match-page-header-score'):wikitext(score)

	local container = mw.html.create('div') :addClass('fb-match-page-header-team-container')
											:addClass('col-sm-4 col-xs-6 col-sm-pull-4')
	if side == 'left' then
		container:node(team):node(scoreDisplay)
	else
		container:node(scoreDisplay):node(team)
	end

	return container
end

---@return string[]
function BigMatch:_getId()
	local title = mw.title.getCurrentTitle().text

	-- Match alphanumeric pattern 10 characters long, followed by space and then the match id
	local staticId = string.match(title, '%w%w%w%w%w%w%w%w%w%w .*')
	local fullBracketId = string.match(title, '%w%w%w%w%w%w%w%w%w%w')
	local matchId = string.sub(staticId, 12)

	return {fullBracketId, matchId}
end

---@param opponent1Players table[]
---@param opponent2Players table[]
---@return table
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

---@param page string?
---@return tournament
function BigMatch:_fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, patch',
		conditions = '[[pagename::'.. page .. ']]',
	})[1] or {}
end

---@param identifiers string[]
---@return string?
function BigMatch:_fetchTournamentLinkFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent, pagename',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
	})[1] or {}
	return Logic.emptyOr(data.parent, data.pagename)
end


return BigMatch
