---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchPage = Lua.import('Module:MatchPage')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Opponent = Lua.import('Module:Opponent')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK_TEAM = 5
local NUM_HEROES_PICK_SOLO = 1
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local NO_CHARACTER = 'default'

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer:addLinks(MatchLinks, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	if MatchPage.isEnabledFor(match) then
		local matchId = match.extradata.originalmatchid or match.matchId
		local matchPageElement = mw.html.create('center')
		matchPageElement:wikitext('[[Match:ID_' .. matchId .. '|Match Page]]')
						:css('display', 'block')
						:css('margin', 'auto')
		body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement):addClass('brkts-popup-mvp'))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex, match.date)
		body:addRow(rowDisplay)
	end

	-- Add Match MVP(s)
	if Table.isNotEmpty(match.extradata.mvp) then
		body.root:node(MatchSummaryWidgets.Mvp{
			players = match.extradata.mvp.players,
			points = match.extradata.mvp.points,
		})
	end

	-- Add the Character Bans
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS, NO_CHARACTER)
	if characterBansData then
		body.root:node(MatchSummaryWidgets.CharacterBanTable{
			bans = characterBansData,
			date = match.date,
		})
	end

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local numberOfHeroes = NUM_HEROES_PICK_TEAM
	if game.mode == Opponent.solo then
		numberOfHeroes = NUM_HEROES_PICK_SOLO
	end

	local heroesData = {{}, {}}
	for heroIndex = 1, numberOfHeroes do
		if String.isNotEmpty(extradata['team1champion' .. heroIndex]) then
			heroesData[1][heroIndex] = extradata['team1champion' .. heroIndex]
		end
		if String.isNotEmpty(extradata['team2champion' .. heroIndex]) then
			heroesData[2][heroIndex] = extradata['team2champion' .. heroIndex]
		end
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(MatchSummaryWidgets.Characters{
		flipped = false,
		date = date,
		characters = heroesData[1],
		bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
	})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(CustomMatchSummary._createAbbreviation{
			title = Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length',
			text = Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
		})
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(MatchSummaryWidgets.Characters{
		flipped = true,
		date = date,
		characters = heroesData[2],
		bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
	})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment:wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(isWinner) then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param args table
---@return string
function CustomMatchSummary._createAbbreviation(args)
	return '<i><abbr title="' .. args.title .. '">' .. args.text .. '</abbr></i>'
end

return CustomMatchSummary
