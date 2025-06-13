---
-- @Liquipedia
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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 3
local NUM_CHAMPIONS_PICK = 5

local FP = Abbreviation.make{text = 'First Pick', title = 'First Pick for Heroes on this map'}

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

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, FnUtil.curry(CustomMatchSummary._createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {emptyMapDisplay = FP}))
	)}
end

---@param date string
---@param game MatchGroupUtilGame
---@return Widget?
function CustomMatchSummary._createGame(date, game)
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1champion', NUM_CHAMPIONS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2champion', NUM_CHAMPIONS_PICK),
	}

	if Logic.isEmpty(game.length) and Logic.isEmpty(game.winner) and Logic.isDeepEmpty(characterData) then
		return nil
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '90%', padding = '4px'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.Characters{
				flipped = false,
				date = date,
				characters = characterData[1],
				bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game), css = {['flex-grow'] = 1}},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				flipped = true,
				date = date,
				characters = characterData[2],
				bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
			},
			MatchSummaryWidgets.GameComment{children = WidgetUtil.collect(
				game.comment,
				game.length and ('Match Duration: ' .. game.length) or nil
			)}
		)
	}
end

return CustomMatchSummary
