---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Icon')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ICONS = {
	left = Icon.makeIcon{iconName = 'left', size = '110%'},
	right = Icon.makeIcon{iconName = 'right', size = '110%'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end

	local function makeTeamSection(opponentIndex)
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			CustomMatchSummary._gameScore(game, opponentIndex)
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.MapAndMode(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			CustomMatchSummary.BanRow(game),
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local opponentCopy = Table.deepCopy(game.opponents[opponentIndex])
	if opponentCopy.score and game.mode == 'Push' then
		opponentCopy.score = opponentCopy.score .. 'm'
	end

	local scoreDisplay = DisplayHelper.MapScore(opponentCopy, game.status)
	return mw.html.create('div'):wikitext(scoreDisplay)
end

---@param game table
---@return Widget?
function CustomMatchSummary.BanRow(game)
	local extradata = game.extradata or {}
	local banStart = extradata.banstart
	local team1Ban = extradata.t1b1
	local team2Ban = extradata.t2b1
	if (not team1Ban) and (not team2Ban) then
		return
	end

	local startIndicator = function(teamIndex)
		local icon = teamIndex ~= banStart and ICONS.empty
			or (teamIndex == 1 and ICONS.left or ICONS.right)

		return HtmlWidgets.Div{
			classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
			children = {icon},
		}
	end

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Break{},
		HtmlWidgets.Div{
			css = {margin = 'auto', ['max-width'] = '100%'},
			children = {
				MatchSummaryWidgets.Character{character = team1Ban},
				startIndicator(1),
				HtmlWidgets.Div{
					classes = {'brkts-popup-spaced'},
					children = {'Ban'},
				},
				startIndicator(2),
				MatchSummaryWidgets.Character{character = team2Ban},
			}
		},
	}}
end

return CustomMatchSummary
