---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ChampionIcon = require('Module:ChampionIcon')
local Table = require('Module:Table')
local ExternalLinks = require('Module:ExternalLinks')
local Array = require('Module:Array')
local String = require('Module:StringUtils')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local _MAX_NUM_BANS = 5
local _NUM_CHAMPIONS_PICK = 5

local _GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'

local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

-- Champion Ban Class
local ChampionBan = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

function ChampionBan:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','36%'):wikitext(''):done()
		:tag('th'):css('width','28%'):wikitext('Bans'):done()
		:tag('th'):css('width','36%'):wikitext(''):done()
	return self
end

function ChampionBan:banRow(banData, gameNumber, numberOfBans)
	self.table:tag('tr')
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[1], numberOfBans, false, true))
		:tag('td')
			:node(mw.html.create('div')
				:wikitext(CustomMatchSummary._createAbbreviation{
					title = 'Bans in game ' .. gameNumber,
					text = 'Game ' .. gameNumber,
				})
			)
		:tag('td')
			:node(CustomMatchSummary._opponentChampionsDisplay(banData[2], numberOfBans, true, true))
	return self
end

function ChampionBan:create()
	return self.root
end

-- MVP Class
local MVP = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-footer'):addClass('brkts-popup-mvp')
		self.players = {}
	end
)

function MVP:addPlayer(player)
	if not Logic.isEmpty(player) then
		table.insert(self.players, player)
	end
	return self
end

function MVP:create()
	local span = mw.html.create('span')
	span:wikitext(#self.players > 1 and 'MVPs: ' or 'MVP: ')
	for index, player in ipairs(self.players) do
		if index > 1 then
			span:wikitext(', ')
		end
		span:wikitext('[['..player..']]')
	end
	self.root:node(span)
	return self.root
end


function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init('420px')
	matchSummary.root:css('flex-wrap', 'unset') -- temporary workaround to fix height, taken from RL

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		comment.root:css('display', 'block'):css('text-align', 'center')
		matchSummary:comment(comment)
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	match.links.lrthread = match.lrthread
	match.links.vod = match.vod
	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Game Vods
		for index, vod in pairs(vods) do
			match.links['vodgame' .. index] = vod
		end

		footer.inner = mw.html.create('div')
			:addClass('bracket-popup-footer plainlinks vodlink')
			:node(ExternalLinks.print(match.links))

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(CustomMatchSummary._createOpponent(match.opponents[1], 'left'))
	      :leftScore(CustomMatchSummary._createScore(match.opponents[1]))
	      :rightScore(CustomMatchSummary._createScore(match.opponents[2]))
	      :rightOpponent(CustomMatchSummary._createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact then
		-- dateIsExact means we have both date and time. Show countdown
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	elseif match.date ~= _EPOCH_TIME_EXTENDED then
		-- if match is not epoch=0, we have a date, so display the date
		-- TODO:Less code duplication, all html stuff is a copy from DisplayHelper.MatchCountdownBlock
		body:addRow(MatchSummary.Row():addElement(
			mw.html.create('div'):addClass('match-countdown-block')
				:css('text-align', 'center')
				-- Workaround for .brkts-popup-body-element > * selector
				:css('display', 'block')
				:wikitext(mw.getContentLanguage():formatDate('F d, Y', match.date))
		))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex)
		if rowDisplay then
			body:addRow(rowDisplay)
		end
	end

	-- Add Match MVP(s)
	local mvpInput = match.extradata.mvp
	if mvpInput then
		local mvpData = mw.text.split(mvpInput or '', ',')
		if String.isNotEmpty(mvpData[1]) then
			local mvp = MVP()
			for _, player in ipairs(mvpData) do
				if String.isNotEmpty(player) then
					mvp:addPlayer(player)
				end
			end

			body:addRow(mvp)
		end

	end

	-- Pre-Process Champion Ban Data
	local showGameBans = {}
	for gameIndex, game in ipairs(match.games) do
		local extradata = game.extradata
		local banData = {{}, {}}
		local numberOfBans = 0
		for index = 1, _MAX_NUM_BANS do
			if String.isNotEmpty(extradata['team1ban' .. index]) then
				numberOfBans = index
				banData[1][index] = extradata['team1ban' .. index]
			end
			if String.isNotEmpty(extradata['team2ban' .. index]) then
				numberOfBans = index
				banData[2][index] = extradata['team2ban' .. index]
			end
		end

		if numberOfBans > 0 then
			banData[1].color = extradata.team1side
			banData[2].color = extradata.team2side
			banData.numberOfBans = numberOfBans
			showGameBans[gameIndex] = banData
		end
	end

	-- Add the Champion Bans
	if not Table.isEmpty(showGameBans) then
		local championBan = ChampionBan()

		for gameIndex, banData in ipairs(showGameBans) do
			championBan:banRow(banData, gameIndex, banData.numberOfBans)
		end

		body:addRow(championBan)
	end

	return body
end

function CustomMatchSummary._createGame(game, gameIndex)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local championsData = {{}, {}}
	local championsDataIsEmpty = true
	for champIndex = 1, _NUM_CHAMPIONS_PICK do
		if String.isNotEmpty(extradata['team1champion' .. champIndex]) then
			championsData[1][champIndex] = extradata['team1champion' .. champIndex]
			championsDataIsEmpty = false
		end
		if String.isNotEmpty(extradata['team2champion' .. champIndex]) then
			championsData[2][champIndex] = extradata['team2champion' .. champIndex]
			championsDataIsEmpty = false
		end
		championsData[1].color = extradata.team1side
		championsData[2].color = extradata.team2side
	end

	if
		String.isEmpty(game.length) and
		String.isEmpty(game.winner) and
		championsDataIsEmpty
	then
		return nil
	end

	row	:addClass('brkts-popup-body-game')
		:css('font-size', '85%')
		:css('overflow', 'hidden')

	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[1], _NUM_CHAMPIONS_PICK, false))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:wikitext(CustomMatchSummary._createAbbreviation{
			title = String.isEmpty(game.length) and ('Game ' .. gameIndex .. 'Picks') or 'Match Length',
			text = game.length or ('Game ' .. gameIndex),
		})
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentChampionsDisplay(championsData[2], _NUM_CHAMPIONS_PICK, true))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '27px')
		:css('margin-left', '3%')
		:css('margin-right', '3%')

	if isWinner then
		container:node(_GREEN_CHECK)
	else
		container:node(_NO_CHECK)
	end

	return container
end

function CustomMatchSummary._createOpponent(opponent, side)
	return OpponentDisplay.BlockOpponent{
		flip = side == 'left',
		opponent = opponent,
		overflow = 'wrap',
		teamStyle = 'short',
	}
end

function CustomMatchSummary._createScore(opponent)
	return OpponentDisplay.BlockScore{
		isWinner = opponent.placement == 1 or opponent.advances,
		scoreText = OpponentDisplay.InlineScore(opponent),
	}
end

function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

function CustomMatchSummary._opponentChampionsDisplay(opponentChampionsData, numberOfChampions, flip, isBan)
	local opponentChampionsDisplay = {}
	local color = opponentChampionsData.color or ''
	opponentChampionsData.color = nil

	for index = 1, numberOfChampions do
		table.insert(opponentChampionsDisplay, ChampionIcon._getImage{
			champ = opponentChampionsData[index],
			size = '25px',
		})
	end

	if flip then
		opponentChampionsDisplay = Array.reverse(opponentChampionsDisplay)
	end

	local display = mw.html.create('div')
	if isBan then
		display:addClass('brkts-popup-side-shade-out')
	end

	return display
		:node(
			mw.html.create('div')
				:addClass('brkts-popup-side-color-' .. color)
				:css('padding', '2px')
				:wikitext(table.concat(opponentChampionsDisplay, ' '))
		)
end

return CustomMatchSummary
