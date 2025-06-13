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
local MapTypeIcon = require('Module:MapType')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
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

---@param game MatchGroupUtilGame
---@return Widget?
function CustomMatchSummary._createMapRow(game)
	if not game.map then
		return
	end

	local function makeTeamSection(opponentIndex)
		local characterData = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('brawler'))
		local teamColor = opponentIndex == 1 and 'blue' or 'red'
		return {
			MatchSummaryWidgets.Characters{
				flipped = opponentIndex == 2,
				characters = characterData,
				bg = 'brkts-popup-side-color-' .. teamColor,
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = CustomMatchSummary._getMapDisplay(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@return Widget
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = LinkWidget{link = game.map}

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		String.isNotEmpty(game.extradata.maptype) and MapTypeIcon.display(game.extradata.maptype) or nil,
		game.status == 'notplayed' and HtmlWidgets.S{children = mapDisplay} or mapDisplay
	)}
end

return CustomMatchSummary
