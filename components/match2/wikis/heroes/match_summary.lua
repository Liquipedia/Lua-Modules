---
-- @Liquipedia
-- wiki=heroes
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 3
local NUM_CHAMPIONS_PICK = 5

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local FP = Abbreviation.make('First Pick', 'First Pick for Heroes on this map')

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)
	local mapVeto = MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto, {emptyMapDisplay = FP})

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, FnUtil.curry(CustomMatchSummary._createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		MatchSummaryWidgets.Casters{casters = match.extradata.casters},
		mapVeto and mapVeto:create() or nil
	)}
end

---@param date string
---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createGame(date, game)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1champion', NUM_CHAMPIONS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2champion', NUM_CHAMPIONS_PICK),
	}

	if Logic.isEmpty(game.length) and Logic.isEmpty(game.winner) and Logic.isDeepEmpty(characterData) then
		return nil
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '90%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(MatchSummaryWidgets.Characters{
		flipped = false,
		date = date,
		characters = characterData[1],
		bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
	})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '120px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext('[[' .. game.map .. ']]')
		)
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(MatchSummaryWidgets.Characters{
		flipped = true,
		date = date,
		characters = characterData[2],
		bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
	})

	if Logic.isNotEmpty(game.comment) or Logic.isNotEmpty(game.length) then
		game.length = Logic.nilIfEmpty(game.length)
		local commentContents = Array.append({},
			Logic.nilIfEmpty(game.comment),
			game.length and tostring(mw.html.create('span'):wikitext('Match Duration: ' .. game.length)) or nil
		)
		row
			:addElement(MatchSummaryWidgets.Break{})
			:addElement(mw.html.create('div')
				:css('margin', 'auto')
				:wikitext(table.concat(commentContents, '<br>'))
			)
	end

	return row:create()
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '27px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if isWinner then
		container:node(GREEN_CHECK )
	else
		container:node(NO_CHECK)
	end

	return container
end

return CustomMatchSummary
