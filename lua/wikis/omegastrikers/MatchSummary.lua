---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local characterBansData = Array.map(match.games, function (game)
		local extradata = game.extradata or {}
		local bans = extradata.bans or {}
		return {bans.team1 or {}, bans.team2 or {}}
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMapRow),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)}
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div'):wikitext(game.opponents[opponentIndex].score)
end

function CustomMatchSummary._createMapRow(game)
	if not game.map then
		return
	end

	local function makeTeamSection(opponentIndex)
		return {
			MatchSummaryWidgets.Characters{
				flipped = opponentIndex == 2,
				characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('striker')),
				bg = opponentIndex == 1 and 'brkts-popup-side-color-blue' or 'brkts-popup-side-color-red',
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
