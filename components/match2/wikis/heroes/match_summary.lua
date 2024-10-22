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
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 3
local NUM_CHAMPIONS_PICK = 5

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local FP = Abbreviation.make('First Pick', 'First Pick for Heroes on this map')
local TBD = Abbreviation.make('TBD', 'To Be Determined')

---@class HeroesOfTheStormMapVeto: VetoDisplay
local MapVeto = Class.new(MatchSummary.MapVeto)

---@param map1 string?
---@param map2 string?
---@return string
---@return string
function MapVeto:displayMaps(map1, map2)
	if Logic.isEmpty(map1) and Logic.isEmpty(map2) then
		return TBD, TBD
	end

	return self:displayMap(map1), self:displayMap(map2)
end

---@param map string?
---@return string
function MapVeto:displayMap(map)
	return Logic.isEmpty(map) and FP or Page.makeInternalLink(map) --[[@as string]]
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default date, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex, match.date)
		if rowDisplay then
			body:addRow(rowDisplay)
		end
	end

	-- Add Match MVP(s)
	if Table.isNotEmpty(match.extradata.mvp) then
		body.root:node(MatchSummaryWidgets.Mvp{
			players = match.extradata.mvp.players,
			points = match.extradata.mvp.points,
		})
	end

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	-- Add the Character Bans
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)
	body.root:node(MatchSummaryWidgets.CharacterBanTable{
		bans = characterBansData,
		date = match.date,
	})

	-- Add the Map Vetoes
	body:addRow(MatchSummary.defaultMapVetoDisplay(match, MapVeto()))

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return MatchSummaryRow?
function CustomMatchSummary._createGame(game, gameIndex, date)
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
			:addElement(MatchSummary.Break():create())
			:addElement(mw.html.create('div')
				:css('margin', 'auto')
				:wikitext(table.concat(commentContents, '<br>'))
			)
	end

	return row
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
