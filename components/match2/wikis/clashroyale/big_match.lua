---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local CardIcon = require('Module:CardIcon')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DivTable = require('Module:DivTable')
local Json = require('Module:Json')
local Links = require('Module:Links')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local VodLink = require('Module:VodLink')

local OpponentDisplay = require('Module:OpponentLibraries').OpponentDisplay

local UTC = '<abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
local NUM_CARDS_PER_PLAYER = 8
local DEFAULT_CARD = 'transparent'
local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local CARD_COLOR_1 = 'blue'
local CARD_COLOR_2 = 'red'

local LINK_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'Live Report Thread'},
	interview = {icon = 'File:Interview32.png', text = 'Interview'},
	recap = {icon = 'File:Reviews32.png', text = 'Recap'},
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
}
LINK_DATA.review = LINK_DATA.recap
LINK_DATA.preview2 = LINK_DATA.preview
LINK_DATA.interview2 = LINK_DATA.interview

local BigMatch = Class.new()

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)
	local bigMatch = BigMatch()

	-- since we retrieve the match completely we do not need to process it nor store it
	local identifiers = bigMatch:_getId()

	local match = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2id::' .. identifiers.fullMatchId .. ']]',
		limit = 1,
	})[1]

	if not match then
		error('No Valid match found')
	end

	-- if we do not have a team opponent we do not want bigMatch used --> error
	if not match.extradata.hasteamopponent then
		error('BigMatch on ClashRoyale is only intended for matches with team opponents.')
	end

	local tournamentData = {
		name = Logic.emptyOr(match.tournament, match.pagename:gsub('_', '')),
		namespace = match.namespace,
		pagename = match.pagename,
		parent = Logic.emptyOr(match.parent, match.pagename),
	}

	local tournament = {
		name = args.tournament or tournamentData.name,
		link = args.tournamentlink or tournamentData.pagename,
		nameSpace = tonumber(args.namespace or tournamentData.namespace) or 0,
	}

	return bigMatch:render(match, tournament)
end

function BigMatch:render(match, tournament)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')

	local opponent1 = match.match2opponents[1]
	local opponent2 = match.match2opponents[2]

	overall :node(self:header(match, opponent1, opponent2, tournament))
			:node(self:overview(match))
			:node(self:body(match))

	return overall
end

function BigMatch:header(match, opponent1, opponent2, tournament)
	local teamLeft = self:_createTeamContainer('left', opponent1.name, opponent1.score, false)
	local teamRight = self:_createTeamContainer('right', opponent2.name, opponent2.score, false)

	local divider = self:_createTeamSeparator(match.format, match)

	local teamsRow = mw.html.create('div')
		:addClass('fb-match-page-header-teams row')
		:css('margin', 0)
		:node(teamLeft)
		:node(divider)
		:node(teamRight)

	local tournamentRow = mw.html.create('div')
		:addClass('fb-match-page-header-tournament')

	if tournament.link and tournament.name then
		tournamentRow:wikitext(BigMatch._tournamentLink(tournament))
	end
	return mw.html.create('div')
		:addClass('fb-match-page-header')
		:node(tournamentRow)
		:node(teamsRow)
end

function BigMatch._tournamentLink(tournament)
	return '[[' .. Namespace.prefixFromId(tournament.nameSpace) .. tournament.link .. '|' .. tournament.name .. ']]'
end

function BigMatch:overview(match)
	local display = DivTable.create():setStriped(true)

	local streams = BigMatch._buildStreams(match.stream)

	display
		:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(table.concat(streams, ' ')))
		)
		:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(
				Countdown.create{
					rawdatetime = true,
					finished = match.finished,
					date = match.date .. UTC
				}
			))
		)

	local linksDisplay = BigMatch._links(match)
	if linksDisplay then
		display:row(
			DivTable.Row():cell(linksDisplay)
		)
	end

	if String.isNotEmpty(match.extradata.comment) then
		display:row(
			DivTable.Row():cell(mw.html.create('div'):wikitext(match.extradata.comment))
		)
	end

	display = display:create()
	display:addClass('fb-match-page-box')

	return mw.html.create('div'):addClass('fb-match-page-overview')
		:node(display)
end

-- kick duplicates and clean streamKeys
function BigMatch._buildStreams(streamsInput)
	local streams = {}
	local uniqueStreams = {}

	for streamKey, stream in pairs(streamsInput) do
		local cleanedStreamKey = streamKey:gsub('_en_%d+$', '') -- remove appended _en_1 etc

		stream = Links.makeFullLink(cleanedStreamKey, stream)

		if String.isNotEmpty(stream) and not uniqueStreams[stream] then
			table.insert(streams, '[' .. stream .. ' <i class="lp-icon lp-' .. cleanedStreamKey .. '></i>]')

			uniqueStreams[stream] = true
		end
	end

	return streams
end

function BigMatch._links(match)
	local vods = {}
	for index, game in ipairs(match.match2games) do
		if not String.isEmpty(game.vod) then
			vods[index] = game.vod
		end
	end

	match.links.vod = match.vod

	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local linksDisplay = mw.html.create('div'):addClass('brkts-popup-spaced vodlink')

		-- Match Vod + other links
		local buildLink = function (link, icon, text)
			return '[['..icon..'|link='..link..'|15px|'..text..']]'
		end

		for linkType, link in pairs(match.links) do
			if not LINK_DATA[linkType] then
				mw.log('Unknown link: ' .. linkType)
			else
				linksDisplay:node(buildLink(link, LINK_DATA[linkType].icon, LINK_DATA[linkType].text))
			end
		end

		-- Game Vods
		for index, vod in pairs(vods) do
			linksDisplay:node(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		return mw.html.create('div')
			:addClass('brkts-popup-footer')
			:node(linksDisplay)
	end

	return
end

function BigMatch:body(match)
	local opponents = match.match2opponents
	local playerLookUp = self:_createPlayerLookUp(opponents[1].match2players, opponents[2].match2players)

	local subMatches = BigMatch._buildSubmatchesFromGames(match, playerLookUp)

	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	for subMatchIndex, subMatch in ipairs(subMatches) do
		tabs['name' .. subMatchIndex] = 'Set ' .. subMatchIndex

		local container = mw.html.create('div')
			:css('display', 'flex')
			:css('flex-direction', 'column')
			:css('align-items', 'center')

		container:node(BigMatch._subMatchHeader(subMatch, subMatchIndex))

		local gameDisplay = DivTable.create():setStriped(true)
			:css('width', '100%')
			:css('max-width', '600px')

		for gameIndex, game in ipairs(subMatch.games) do
			gameDisplay:row(BigMatch._gameRow(game, gameIndex, playerLookUp, match.date, subMatch.isKoth))

			if Table.isNotEmpty(game.bans) then
				gameDisplay:row(BigMatch._banRow(game.bans, match.date, gameIndex))
			end

			if String.isNotEmpty(game.extradata.comment) then
				gameDisplay:row(BigMatch._gameComment(game.extradata.comment))
			end
		end

		if Table.isNotEmpty(subMatch.bans) then
			gameDisplay:row(BigMatch._banRow(subMatch.bans, match.date))
		end

		container:node(gameDisplay:create())

		tabs['content' .. subMatchIndex] = tostring(container)
	end

	return Tabs.dynamic(tabs)
end

function BigMatch._buildSubmatchesFromGames(match, playerLookUp)
	local subMatches = match.extradata.submatches
	local extradata = match.extradata
	local t1Bans = extradata.t1bans
	local t2Bans = extradata.t2bans

	for gameIndex, game in ipairs(match.match2games) do
		game.subgroup = tonumber(game.subgroup)
		local subMatch = subMatches[game.subgroup]
		if not subMatch.games then
			local prefix = 'subgroup' .. game.subgroup
			subMatch.games = {}
			subMatch.isKoth = extradata[prefix .. 'iskoth']
			subMatch.header = extradata[prefix .. 'header']
			subMatch.players = {{}, {}, hash = {{}, {}}}
			subMatch.bans = {
				t1 = extradata[prefix .. 't1bans'],
				t2 = extradata[prefix .. 't2bans'],
			}
		end

		game.bans = {
			t1 = t1Bans[gameIndex],
			t2 = t2Bans[gameIndex],
		}

		BigMatch._fetchSubMatchPlayersFromGame(subMatch.players, game, playerLookUp)

		table.insert(subMatch.games, game)
	end

	return subMatches
end

function BigMatch._fetchSubMatchPlayersFromGame(players, game, playerLookUp)
	game.participants = type(game.participants) == 'table' and game.participants
		or Json.parseIfTable(game.participants) or {}

	for participantKey, participant in Table.iter.spairs(game.participants) do
		local opponentIndex = tonumber(mw.text.split(participantKey, '_')[1])

		local player = playerLookUp[participantKey] or {}
		player = {
			displayName = player.displayname or participant.displayname,
			pageName = player.name or participant.name,
			flag = player.flag,
		}

		-- make sure we only display each player once
		if not players.hash[opponentIndex][player.pageName] then
			players.hash[opponentIndex][player.pageName] = true
			table.insert(players[opponentIndex], player)
		end
	end

	return players
end

function BigMatch._subMatchHeader(subMatch, subMatchIndex)
	local header = mw.html.create('div')
		:css('font-weight', 'bold')
		:wikitext(subMatch.header or ('Set ' .. subMatchIndex))

	local kothElement = mw.html.create('div')
	if subMatch.isKoth then
		kothElement:wikitext(Abbreviation.make('KotH', 'King of the Hill submatch'))
	end

	local infoHeader = mw.html.create('div')
		-- move to css!!!
		:css('width', '100%')
		:css('max-width', '600px')
		:css('display', 'flex')
		:css('justify-content', 'space-between')
		:css('padding', '10px')
		:css('margin-bottom', '5px')
		:css('margin-top', '10px')
		:css('font-size', '20px')
		:node(header)
		:node(kothElement)

	local playersLeftDisplay = mw.html.create('div')
		:addClass(subMatch.winner == 1 and 'bg-win' or nil)
		-- move to css!!!
		:css('align-items', 'center')
		:css('border-radius', '0 12px 12px 0')
		:css('padding', '2px 8px')
		:css('text-align', 'right')
		:css('width', '40%')
		:node(OpponentDisplay.PlayerBlockOpponent{
			opponent = {players = subMatch.players[1]},
			overflow = 'ellipsis',
			showLink = true,
			flip = true,
		})

	local scoreElement = mw.html.create('div')
		:css('width', '20%')
		:css('display', 'flex')
		:css('justify-content', 'center')
		:css('align-items', 'center')
		:wikitext(table.concat(subMatch.scores, ' - '))

	local playersRightDisplay = mw.html.create('div')
		:addClass(subMatch.winner == 2 and 'bg-win' or nil)
		-- move to css!!!
		:css('align-items', 'center')
		:css('border-radius', '12px 0 0 12px')
		:css('padding', '2px 8px')
		:css('text-align', 'left')
		:css('width', '40%')
		:node(OpponentDisplay.PlayerBlockOpponent{
			opponent = {players = subMatch.players[2]},
			overflow = 'ellipsis',
			showLink = true,
			flip = false
		})

	local resultsHeader = mw.html.create('div')
		-- move to css!!!
		:css('width', '100%')
		:css('max-width', '600px')
		:css('display', 'flex')
		:css('justify-content', 'space-between')
		:css('border', '1px solid #bbbbbb')
		:css('padding', '10px')
		:css('margin-bottom', '0px')
		:css('font-size', '16px')
		:node(playersLeftDisplay)
		:node(scoreElement)
		:node(playersRightDisplay)

	return mw.html.create()
		:node(infoHeader)
		:node(resultsHeader)
end

function BigMatch._gameRow(game, gameIndex, playerLookUp, date, isKoth)
	local row = DivTable.Row()

	local players = BigMatch._fetchGamePlayers(game, playerLookUp)

	-- cards & player display left side
	row:cell(BigMatch._cardsAndPlayerDisplay(players[1], true, isKoth, date))

	-- winner Icon if left won
	row:cell(mw.html.create('div')
		:css('vertical-align', 'middle')
		:css('text-align', 'left')
		:node(BigMatch._WinnerIcon(game, 1))
	)

	-- generic game text
	row:cell(mw.html.create('div')
		:css('text-align', 'center')
		:css('vertical-align', 'middle')
		:wikitext(Abbreviation.make('G' .. gameIndex, 'Game ' .. gameIndex))
	)

	-- winner Icon if right won
	row:cell(mw.html.create('div')
		:css('vertical-align', 'middle')
		:css('text-align', 'right')
		:node(BigMatch._WinnerIcon(game, 2))
	)

	row:cell(BigMatch._cardsAndPlayerDisplay(players[2], false, isKoth, date))

	return row
end

function BigMatch._fetchGamePlayers(game, playerLookUp)
	local players = {{}, {}}

	for participantKey, participant in Table.iter.spairs(game.participants or {}) do
		local opponentIndex = tonumber(mw.text.split(participantKey, '_')[1])

		local player = playerLookUp[participantKey] or {}
		player = {
			displayName = player.displayname or participant.displayname,
			pageName = player.name or participant.name,
			flag = player.flag,
			cards = BigMatch._fillUpCards(participant.cards),
		}

		table.insert(players[opponentIndex], player)
	end

	return players
end

function BigMatch._cardsAndPlayerDisplay(players, flip, isKoth, date)
	local container = mw.html.create('div')
		:css('display', 'flex')
		:css('flex-direction', 'column')

	for _, player in ipairs(players or {}) do
		if isKoth then
			container:node(mw.html.create('div')
				:css('text-align', flip and 'right' or 'left')
				:node(OpponentDisplay.PlayerBlockOpponent{
					opponent = {players = {player}},
					overflow = 'ellipsis',
					showLink = true,
					flip = flip,
				})
			)
		end

		container:node(BigMatch._cardsDisplay{
			data = player.cards,
			flip = flip,
			date = date,
		})
	end

	return container
end

function BigMatch._gameComment(comment)
	-- ugly hack to have comment span over all cells in the row
	return DivTable.Row()
		:cell(mw.html.create('div')
			:css('display', 'table-cell')
			:css('max-width', '1px')
			:css('white-space', 'nowrap')
			:css('overflow', 'visible')
			:wikitext(comment))
		:cell(mw.html.create('div'))
		:cell(mw.html.create('div'))
		:cell(mw.html.create('div'))
		:cell(mw.html.create('div'))
end

function BigMatch._banRow(bans, date, gameIndex)
	local row = DivTable.Row()

	if type(bans.t1) ~= 'table' then
		bans.t1 = {bans.t1}
	end
	if type(bans.t2) ~= 'table' then
		bans.t2 = {bans.t2}
	end

	-- cards display left side
	row:cell(BigMatch._cardsDisplay{
		data = bans.t1,
		flip = true,
		date = date,
	})

	-- placeholder
	row
		:cell(mw.html.create('div'))

	-- info text
	row:cell(mw.html.create('div')
		:css('text-align', 'center')
		:css('vertical-align', 'middle')
		:wikitext(gameIndex and Abbreviation.make('B' .. gameIndex, 'Game ' .. gameIndex .. ' bans')
			or Abbreviation.make('B', 'Set bans')
		)
	)

	-- placeholder
	row
		:cell(mw.html.create('div'))

	-- cards display right side
	row:cell(BigMatch._cardsDisplay{
		data = bans.t2,
		flip = false,
		date = date,
	})

	return row
end

function BigMatch._fillUpCards(cards)
	for cardIndex = 1, NUM_CARDS_PER_PLAYER do
		cards[cardIndex] = cards[cardIndex] or DEFAULT_CARD
	end

	return cards
end

function BigMatch._WinnerIcon(game, opponentIndex)
	local container = mw.html.create('div')

	if tonumber(game.winner) == opponentIndex then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

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
	format = mw.html.create('div')
		:addClass('fb-match-page-header-format')
		:wikitext(format)
	return mw.html.create('div')
		:addClass('fb-match-page-header-separator')
		:node(countdown)
		:node(divider)
		:node(format)
end


function BigMatch:_createTeamContainer(side, teamName, score, hasWon)
	local link = '[[' .. teamName .. ']]'
	local team = mw.html.create('div')	:addClass('fb-match-page-header-team')
										:wikitext(mw.ext.TeamTemplate.teamicon(teamName) .. '<br/>' .. link)
	score = mw.html.create('div'):addClass('fb-match-page-header-score'):wikitext(score)

	local container = mw.html.create('div') :addClass('fb-match-page-header-team-container')
											:addClass('col-sm-4 col-xs-6 col-sm-pull-4')
	if side == 'left' then
		container:node(team:css('padding-right', '20px')):node(score)
	else
		container:node(score):node(team:css('padding-left', '20px'))
	end

	return container
end

function BigMatch:_getId()
	local title = mw.title.getCurrentTitle().text

	-- Match alphanumeric pattern 10 characters long, followed by space and then the match id
	local staticId = string.match(title, '%w%w%w%w%w%w%w%w%w%w .*')
	local bracketId = string.match(title, '%w%w%w%w%w%w%w%w%w%w')
	local matchId = string.sub(staticId, 12)
	local fullBracketId = string.sub(title, 1, -2 - string.len(matchId)):gsub(' ', '_'):gsub('Match:ID_', '')
	local fullMatchId = fullBracketId .. '_' .. matchId

	return {bracketId, matchId, fullMatchId = fullMatchId}
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

function BigMatch:_fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::'.. page .. ']]',
		query = 'pagename, name, parent, namespace',
	})[1] or {}
end

function BigMatch:_fetchTournamentLinkFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent, pagename',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
	})[1] or {}
	return Logic.emptyOr(data.parent, data.pagename)
end

function BigMatch._cardsDisplay(args)
	local cards = args.data
	local flip = args.flip
	local date = args.date
	local color = flip and CARD_COLOR_2 or CARD_COLOR_1

	local display = mw.html.create('div')
		:addClass('brkts-popup-body-element-thumbs')

	for _, card in ipairs(cards) do
		display:node(mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. color)
			:addClass('brkts-champion-icon')
			:css('float', flip and 'right' or 'left')
			:node(CardIcon._getImage{card, date = date})
		)
	end

	return display
end

return BigMatch
