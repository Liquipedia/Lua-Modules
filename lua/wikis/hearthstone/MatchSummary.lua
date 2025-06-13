---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '350px', teamStyle = 'bracket'})
end

---@param match HearthstoneMatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local submatches
	if match.isTeamMatch then
		submatches = match.submatches or {}
	end

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		submatches and Array.map(submatches, CustomMatchSummary.TeamSubmatch)
			or Array.map(match.games, FnUtil.curry(CustomMatchSummary.Game, {isPartOfSubMatch = false}))
	)}
end

---@param submatch HearthstoneMatchGroupUtilSubmatch
---@return MatchSummaryRow
function CustomMatchSummary.TeamSubmatch(submatch)
	local hasDetails = CustomMatchSummary._submatchHasDetails(submatch)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			submatch.header and {
				HtmlWidgets.Div{css = {margin = 'auto', ['font-weight'] = 'bold'}, children = {submatch.header}},
				MatchSummaryWidgets.Break{},
			} or nil,
			CustomMatchSummary.TeamSubMatchOpponnetRow(submatch),
			hasDetails and Array.map(submatch.games, function(game, gameIndex)
				return CustomMatchSummary.Game(
					{isPartOfSubMatch = true},
					game,
					gameIndex
				)
			end) or nil
		)
	}
end

---@param submatch HearthstoneMatchGroupUtilSubmatch
---@return boolean
function CustomMatchSummary._submatchHasDetails(submatch)
	return #submatch.games > 0 and Array.any(submatch.games, function(game)
		return not string.find(game.map or '', '^[sS]ubmatch %d+$')
	end)
end

---@param submatch HearthstoneMatchGroupUtilSubmatch
---@return Html
function CustomMatchSummary.TeamSubMatchOpponnetRow(submatch)
	local opponents = submatch.opponents or {{}, {}}
	Array.forEach(opponents, function (opponent, opponentIndex)
		local players = opponent.players or {}
		if Logic.isEmpty(players) then
			players = Opponent.tbd(Opponent.solo).players
		end
		---@cast players -nil
		opponent.type = Opponent.partyTypes[math.max(#players, 1)]
		opponent.players = players
	end)

	return HtmlWidgets.Div {
		css = {margin = 'auto'},
		children = MatchSummary.createDefaultHeader({opponents = opponents}):create()
	}
end

---@param options {isPartOfSubMatch: boolean?}
---@param game MatchGroupUtilGame
---@param gameIndex number
---@return Widget
function CustomMatchSummary.Game(options, game, gameIndex)
	local rowWidget = options.isPartOfSubMatch and HtmlWidgets.Div or MatchSummaryWidgets.Row

	---@param opponentIndex any
	---@return table[]
	local function createOpponentDisplay(opponentIndex)
		return Array.extend({
			CustomMatchSummary.DisplayClass(game.opponents[opponentIndex], opponentIndex == 1),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
		})
	end

	return rowWidget{
		classes = {'brkts-popup-body-game'},
		css = {width = options.isPartOfSubMatch and '100%' or nil, ['font-size'] = '0.75rem'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = createOpponentDisplay(1)},
			MatchSummaryWidgets.GameCenter{css = {flex = '0 0 16%'}, children = 'Game ' .. gameIndex},
			MatchSummaryWidgets.GameTeamWrapper{children = createOpponentDisplay(2), flipped = true}
		)
	}
end

---@param opponent table
---@param flip boolean?
---@return Html?
function CustomMatchSummary.DisplayClass(opponent, flip)
	local player = Array.find(opponent.players or {}, function (player)
		return Logic.isNotEmpty(player.class)
	end)

	if Logic.isEmpty(player) then
		return nil
	end
	---@cast player -nil

	return HtmlWidgets.Div{
		classes = {'brkts-champion-icon'},
		css = {
			display = 'flex',
			flex = '1',
			['justify-content'] = flip and 'flex-end' or 'flex-start'
		},
		children = MatchSummaryWidgets.Character{
			character = player.class,
			showName = true,
			flipped = flip,
		}
	}
end

return CustomMatchSummary
