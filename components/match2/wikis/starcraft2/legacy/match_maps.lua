---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Match maps
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- This module generates the old display of "match maps" calls in matchlists.
-- For "match maps" calls inside a matchlist started by "Template:Legacy Match list start"
-- it also converts the input args so that they can be ready
-- by the input processing of the match2 implementation.

local Countdown = require('Module:Countdown')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local MapVeto = require('Module:MapVeto')
local MapWinner = require('Module:MapWinner')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Player = require('Module:Player')
local Template = require('Module:Template')
local Class = require('Module:Class')
local Table = require('Module:Table')
local WikiSpecific = require('Module:Brkts/WikiSpecific')
local RaceIcon = require('Module:RaceIcon')
local Vodlink = require('Module:Vodlink')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local _GAME_NUMBER_MAX = 9
local _VETO_NUMBER_MAX = 4
local _OPPONENT_NUMBER = 2
local _WALKOVER_TO_SCORE = {
	['0'] = {'-', '-'},
	['1'] = {'W', '-'},
	['2'] = {'-', 'W'},
}
local _LINK_PARAMS = {
	preview = {
		file = 'Preview Icon.png',
		text = 'Preview',
	},
	lrthread = {
		file = 'LiveReport.png',
		text = 'Live Report Thread',
	},
	interview = {
		file = 'Int Icon.png',
		text = 'Interview',
	},
	review = {
		file = 'Writers Icon.png',
		text = 'Review',
	},
	recap = {
		file = 'Writers Icon.png',
		text = 'Recap',
	},
}

local _args

local MatchMaps = {}

function MatchMaps.run(args)
	_args = args
	MatchMaps._setPlayerVars()
	globalVars:set('bestof', args.bestof or globalVars:get('bestof') or '')

	local matchDate = globalVars:get('Match_date') or globalVars:get('Group_date') or ''
	local timeZone = globalVars:get('timezone') or ''

	local dateHeader
	dateHeader, matchDate, timeZone = MatchMaps._dateHeader(matchDate, timeZone)

	matchDate = MatchMaps._dateHandling(matchDate)

	local matchRow, scores = MatchMaps._matchRow()

	local output = mw.html.create()
		:node(MatchMaps._title(args.title))
		:node(dateHeader)
		:node(matchRow)
		:node(MatchMaps._maps(scores))
		:node(MatchMaps._links())
		:node(MatchMaps._comment())

	MatchMaps._reset_vars()
	if
		Logic.readBool(matchlistVars:get('store'))
		and matchlistVars:get('bracketid')
	then
		MatchMaps._prepareToStore(matchDate, timeZone)
	end

	return output
end

function MatchMaps._setPlayerVars()
	local args = _args
	local player1Id = MatchMaps._cleanPlayerInput(args.player1 or 'TBD')
	local player2Id = MatchMaps._cleanPlayerInput(args.player2 or 'TBD')

	local player1Race = args.player1race or globalVars:get(player1Id .. '_race') or 'TBD'
	args.player1Race = player1Race
	local player2Race = args.player2race or globalVars:get(player2Id .. '_race') or 'TBD'
	args.player2Race = player2Race
	local player1Flag = args.player1flag or globalVars:get(player1Id .. '_flag') or 'TBD'
	local player2Flag = args.player2flag or globalVars:get(player2Id .. '_flag') or 'TBD'

	globalVars:set('player1', player1Id)
	globalVars:set('player2', player2Id)
	globalVars:set('player1_race', player1Race)
	globalVars:set('player2_race', player2Race)
	globalVars:set('player1_flag', player1Flag)
	globalVars:set('player2_flag', player2Flag)
end

function MatchMaps._cleanPlayerInput(player)
	player = player:gsub('%b{}', '')
	player = player:gsub('%b<>', '')
	player = player:gsub('%b[]', '')
	player = mw.text.trim(player)

	return player
end

function MatchMaps._title(title)
	if String.isEmpty(title) then
		return nil
	end

	return mw.html.create('tr'):tag('td')
		:attr('colspan', 4)
		:css('font-weight', 'bold')
		:css('background-color', '#f2f2f2')
		:css('font-size', '85%')
		:css('line-height', '12.5px')
		:css('height', '13px')
		:css('text-align', 'center')
		:wikitext(title)
end

function MatchMaps._dateHeader(matchDate, timeZone)
	local args = _args
	if String.isEmpty(args.date) then
		return nil, matchDate, timeZone
	end

	local rawMatchDate = args.date:gsub('<.*', '')
	matchDate = rawMatchDate:gsub('- ', '')
	timeZone = args.date:match('data%-tz="([+-].-)"') or ''
	-- Storing date info via #vardefine for the following matches
	globalVars:set('Raw_Match_date', rawMatchDate)
	globalVars:set('timezone', timeZone)
	-- For the Match_date vardefine, see a few lines below

	local dateRow = mw.html.create('tr'):tag('td')
		:attr('colspan', 4)
		:addClass('grouptable-start-date')
		:css('font-weight', 'bold')
		:wikitext(Countdown._create(args))

	return dateRow, matchDate, timeZone
end

function MatchMaps._dateHandling(matchDate)
	-- date handling for following matches
	local matchDatePlus1Second
	if String.isNotEmpty(matchDate) then
		-- We add 1 second for the following match so that the order of games is preserved
		matchDatePlus1Second = mw.getCurrentFrame():callParserFunction('#time:Y-m-d H:i:s', matchDate .. ' +1 second')
		globalVars:set('Match_date', matchDatePlus1Second)
	else
		local matchDateInfobox = globalVars:get('tournament_enddate') or globalVars:get('tournament_startdate')
		if String.isNotEmpty(matchDateInfobox) then
			matchDatePlus1Second = mw.getCurrentFrame():callParserFunction('#time:Y-m-d H:i:s', matchDateInfobox .. ' +1 second')
			matchDate = matchDateInfobox
			globalVars:set('Match_date', matchDatePlus1Second)
		end
	end

	return matchDate
end

function MatchMaps._matchRow()
	local args = _args

	-- determine scores
	local scores = _WALKOVER_TO_SCORE[args.walkover or ''] or {0, 0}
	if args.p1score and args.p2score then
		scores = {args.p1score, args.p2score}
	else
		for gameIndex = 1, _GAME_NUMBER_MAX do
			scores[1] = scores[1] + (args['map' .. gameIndex .. 'win'] == '1' and 1 or 0)
			scores[2] = scores[2] + (args['map' .. gameIndex .. 'win'] == '2' and 1 or 0)
		end
	end

	local isDraw = args.winner == 'draw'

	local playerLeftNode = MatchMaps._playerNode(1, isDraw)
	local playerRightNode = MatchMaps._playerNode(2, isDraw)

	local scoreLeftNode = MatchMaps._scoreNode(scores[1], isDraw or args.winner == '1')
	local scoreRightNode = MatchMaps._scoreNode(scores[2], isDraw or args.winner == '2')

	if args.details then
		local width = args.width or 300
		width = (width-640)/2

		local popupWrapper = scoreLeftNode:tag('div')
			:addClass('bracket-popup-wrapper')
			:addClass('bracket-popup-player')
			:css('margin-left', width .. 'px')
		local popup = popupWrapper:tag('div')
			:addClass('bracket-popup')
		popup:node(MatchMaps._popupHeader())
		popup:wikitext(args.details)
	end

	local matchRow = mw.html.create('tr')
		:addClass('match-row')
		:node(playerLeftNode)
		:node(scoreLeftNode)
		:node(scoreRightNode)
		:node(playerRightNode)

	return matchRow, scores
end

function MatchMaps._playerNode(playerIndex, isDraw)
	local args = _args
	local playerNode = mw.html.create('td')
		:addClass('matchlistslot')
		:css('width', '42%')

	if playerIndex == 1 then
		playerNode:css('text-align', 'right')
	end

	playerNode:wikitext(
		Player['_player' .. (playerIndex == 1 and '2' or '')]({
			args['player' .. playerIndex],
			link = args['playerlink' .. playerIndex] or args.playerlink or 'false',
			flag = args['player' .. playerIndex .. 'flag'],
			race = args['player' .. playerIndex .. 'Race'],
			novar = 'true'
		})
	)

	if isDraw then
		playerNode:css('font-weight', 'bold')
			:addClass('bg-draw')
	elseif (tonumber(args.winner or 0) or 0) == playerIndex then
		playerNode:css('font-weight', 'bold')
			:addClass('bg-win')
	end

	return playerNode
end

function MatchMaps._scoreNode(score, isBold)
	local scoreNode = mw.html.create('td')
		:css('width', '8%')
		:css('text-align', 'center')
		:wikitext(score)

	if isBold then
		scoreNode:css('font-weight', 'bold')
	end

	return scoreNode
end

function MatchMaps._maps(scores)
local args = _args

	local maps = {}
	for mapIndex = 1, _GAME_NUMBER_MAX do
		local currentMap = args['map' .. mapIndex]
		if String.isNotEmpty(currentMap) then
			table.insert(maps, {
					currentMap,
					args['map' .. mapIndex .. 'win'] or '',
					args['map' .. mapIndex .. 'p1race'] or '',
					args['map' .. mapIndex .. 'p2race'] or '',
				}
			)
		end
	end

	if #maps > 0 then

		local mapsDisplay = mw.html.create('td')
			:attr('colspan', 4)
			:css('font-size', '85%')
			:css('line-height', '130%')
			:css('text-align', 'left')

		for _, mapData in ipairs(maps) do
			mapsDisplay:wikitext(MapWinner._create(mapData))
		end

		for vetoIndex = 1, _VETO_NUMBER_MAX do
			local currentVeto = args['veto' .. vetoIndex]
			if String.isNotEmpty(currentVeto) then
				mapsDisplay:wikitext(MapVeto._create({
						currentVeto,
						args['vetoplayer' .. vetoIndex] or '',
					})
				)
			end
		end

		return mw.html.create('tr')
			:addClass('maprow')
			:node(mapsDisplay)

	elseif String.isEmpty(args.walkover) then
		globalVars:set('player1wins', scores[1])
		globalVars:set('player2wins', scores[2])
	end
end

function MatchMaps._links()
	local args = _args
	local links = {}
	for linkParam, linkData in pairs(_LINK_PARAMS) do
		if String.isNotEmpty(args[linkParam]) then
			table.insert(
				links,
				'[[File:' .. linkData.file ..
					'|link=' .. args[linkParam] ..
					'|alt=' .. linkParam .. '|15px|' ..
					linkData.text .. ']]'
			)
		end
	end

	if String.isNotEmpty(args.vod) then
		table.insert(
			links,
			Vodlink._main{vod = args.vod, source = 'url'}
		)
	end

	for vodIndex = 1, _GAME_NUMBER_MAX do
		if String.isNotEmpty(args['vodgame' .. vodIndex]) then
			table.insert(
				links,
				Vodlink._main{amenum = vodIndex, vod = args['vodgame' .. vodIndex], source = 'url'}
			)
		end
	end

	if #links > 0 then
		local linksCell = mw.html.create('td')
			:attr('colspan', 4)
			:css('text-align', 'center')
			:wikitext(table.concat(links, ' '))

		return mw.html.create('tr')
			:addClass('maprow')
			:node(linksCell)
	end
end

function MatchMaps._comment()
	local comment = _args.comment
	if String.isNotEmpty(comment) then
		comment = comment:gsub('%<small%>', '')
		comment = comment:gsub('%<%/small%>', '')
		return mw.html.create('tr')
			:tag('td')
			:attr('colspan', 4)
			:css('text-align', 'center')
			:wikitext('<small>' .. comment .. '</small>')
	end
end

-- convert params for match2 storage
function MatchMaps._prepareToStore(matchDate, timeZone)
	local storageArgs = Table.copy(_args)

	-- opponents
	for opponentIndex = 1, _OPPONENT_NUMBER do
		storageArgs['opponent' .. opponentIndex] = {
			['type'] = 'solo',
			name = storageArgs['player' .. opponentIndex],
			link = storageArgs['playerlink' .. opponentIndex],
			race = storageArgs['player' .. opponentIndex .. 'race'],
			flag = storageArgs['player' .. opponentIndex .. 'flag'],
			score = storageArgs['p' .. opponentIndex .. 'score'],
		}
		storageArgs['player' .. opponentIndex] = nil
		storageArgs['playerlink' .. opponentIndex] = nil
		storageArgs['player' .. opponentIndex .. 'race'] = nil
		storageArgs['player' .. opponentIndex .. 'flag'] = nil
		storageArgs['p' .. opponentIndex .. 'score'] = nil
	end

	-- maps
	for gameIndex = 1, _GAME_NUMBER_MAX do
		if
			String.isNotEmpty(storageArgs['map' .. gameIndex]) or
			String.isNotEmpty(storageArgs['map' .. gameIndex .. 'win'])
		then
			local temp = storageArgs['map' .. gameIndex]
			storageArgs['map' .. gameIndex] = {
				map = temp or 'unknown',
				winner = storageArgs['map' .. gameIndex .. 'win'],
				race1 = storageArgs['map' .. gameIndex .. 'p1race'],
				race2 = storageArgs['map' .. gameIndex .. 'p2race'],
			}
			storageArgs['map' .. gameIndex .. 'win'] = nil
			storageArgs['map' .. gameIndex .. 'p1race'] = nil
			storageArgs['map' .. gameIndex .. 'p2race'] = nil
		else
			break
		end
	end

	-- fix date
	storageArgs.date = mw.getContentLanguage():formatDate('c', matchDate .. timeZone)

	-- call match2 processing
	storageArgs = WikiSpecific.processMatch(nil, storageArgs)
	Template.stashReturnValue(storageArgs, 'LegacyMatchlist')
end

function MatchMaps._reset_vars()
	globalVars:set('player1wins', 0)
	globalVars:set('player2wins', 0)
	globalVars:delete('finished')
	globalVars:set('match_number', (globalVars:get('match_number') or 1) + 1)
end

-- MatchMaps._popupHeader
-- @param	args	template arguments
-- @return			the wikitext part for just the header
function MatchMaps._popupHeader()
	local args = _args
	local header = mw.html.create('div')
		:addClass('bracket-popup-header')

	header:tag('div')
		:addClass('bracket-popup-header-left')
		:wikitext(args.player1 or 'TBD')
		:wikitext('&nbsp;' .. MatchMaps._race(args.player1Race))

	header:tag('div')
		:addClass('bracket-popup-header-right')
		:wikitext(MatchMaps._race(args.player2Race) .. '&nbsp;')
		:wikitext(args.player2 or 'TBD')

	return header
end

-- MatchMaps._race
-- @param	race	the race initial
-- @return			the wikitext for {{RaceIconSmall|race}}
function MatchMaps._race(race)
	if String.isNotEmpty(race) then
		return RaceIcon.getSmallIcon({race})
	end

	return ''
end

return Class.export(MatchMaps)
