---
-- @Liquipedia
-- page=Module:MatchSummary/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchGroupUtilStarcraft = Lua.import('Module:MatchGroup/Util/Custom')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ICONS = {
	veto = Icon.makeIcon{iconName = 'veto', color = 'cinnabar-text', size = '110%'},
	noCheck = '[[File:NoCheck.png|link=|16px]]',
}

local UNIFORM_MATCH = 'uniform'
local TBD = 'TBD'

local StarcraftMatchSummary = {}

---@param args {bracketId: string, matchId: string, config: table?}
---@return Html
function StarcraftMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(StarcraftMatchSummary, args):addClass('brkts-popup-sc')
end

---@param match StarcraftMatchGroupUtilMatch
---@return MatchSummaryBody
function StarcraftMatchSummary.createBody(match)
	StarcraftMatchSummary.computeOffFactions(match)

	local isResetMatch = String.endsWith(match.matchId, '_RxMBR')
	local subMatches
	if match.opponentMode ~= UNIFORM_MATCH then
		subMatches = match.submatches or {}
	end

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		isResetMatch and MatchSummaryWidgets.Row{
			classes = {'brkts-popup-sc-veto-center'},
			css = {['line-height'] = '80%', ['font-weight'] = 'bold'},
			children = {'Reset match'},
		} or nil,
		match.dateIsExact and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.opponents, StarcraftMatchSummary.advantageOrPenalty),
		subMatches and Array.map(subMatches, StarcraftMatchSummary.TeamSubmatch)
			or Array.map(match.games, FnUtil.curry(StarcraftMatchSummary.Game, {})),
		Logic.isNotEmpty(match.vetoes) and MatchSummaryWidgets.Row{
			classes = {'brkts-popup-sc-game-header brkts-popup-sc-veto-center'},
			children = {'Vetoes'},
		} or nil,
		Array.map(match.vetoes or {}, StarcraftMatchSummary.Veto) or nil
	)}
end

---@param match StarcraftMatchGroupUtilMatch
function StarcraftMatchSummary.computeOffFactions(match)
	if match.opponentMode == UNIFORM_MATCH then
		StarcraftMatchSummary.computeMatchOffFactions(match)
	else
		for _, submatch in pairs(match.submatches) do
			StarcraftMatchSummary.computeMatchOffFactions(submatch)
		end
	end
end

---@param match StarcraftMatchGroupUtilMatch|StarcraftMatchGroupUtilSubmatch
function StarcraftMatchSummary.computeMatchOffFactions(match)
	for _, game in ipairs(match.games) do
		game.offFactions = {}
		for opponentIndex, gameOpponent in pairs(game.opponents) do
			game.offFactions[opponentIndex] = MatchGroupUtilStarcraft.computeOffFactions(
				gameOpponent,
				match.opponents[opponentIndex]
			)
		end
	end
end

---@param opponent StarcraftStandardOpponent
---@return Widget?
function StarcraftMatchSummary.advantageOrPenalty(opponent)
	local extradata = opponent.extradata or {}
	if not Logic.isNumeric(extradata.advantage) and not Logic.isNumeric(extradata.penalty) then
		return nil
	end
	local infoType = Logic.isNumeric(extradata.advantage) and 'advantage' or 'penalty'
	local value = tonumber(extradata.advantage) or tonumber(extradata.penalty)

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-sc-game-center'},
		children = {
			OpponentDisplay.InlineOpponent{
				opponent = Opponent.isTbd(opponent) and Opponent.tbd() or opponent,
				showFlag = false,
				showLink = true,
				showFaction = false,
				teamStyle = 'short',
			},
			' starts with a ' .. value .. ' map ' .. infoType .. '.',
		},
	}
end

---@param options {noLink: boolean?, isPartOfSubMatch: boolean?}
---@param game StarcraftMatchGroupUtilGame
---@return MatchSummaryRow
function StarcraftMatchSummary.Game(options, game)
	local noLink = options.noLink or (game.map or ''):upper() == TBD

	local showOffFactionIcons = game.offFactions ~= nil and (game.offFactions[1] ~= nil or game.offFactions[2] ~= nil)
	local offFactionIcons = function(opponentIndex)
		local offFactions = game.offFactions ~= nil and game.offFactions[opponentIndex] or nil
		local opponent = game.opponents ~= nil and game.opponents[opponentIndex] or nil

		if offFactions and opponent and opponent.isArchon then
			return StarcraftMatchSummary.OffFactionIcons({offFactions[1]})
		elseif offFactions and opponent then
			return StarcraftMatchSummary.OffFactionIcons(offFactions)
		elseif showOffFactionIcons then
			return StarcraftMatchSummary.OffFactionIcons({})
		else
			return nil
		end
	end

	local rowWidget = options.isPartOfSubMatch and HtmlWidgets.Div or MatchSummaryWidgets.Row

	return rowWidget{
		classes = {'brkts-popup-body-game'},
		css = {width = options.isPartOfSubMatch and '100%' or nil},
		children = WidgetUtil.collect(
			game.header and {
				HtmlWidgets.Div{css = {margin = 'auto'}, children = {game.header}},
				MatchSummaryWidgets.Break{},
			} or nil,
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			offFactionIcons(1),
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.MapAndStatus(game, {noLink = noLink})},
			offFactionIcons(2),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{
				children = (game.extradata or {}).server and ('Played server: ' .. (game.extradata or {}).server) or nil,
				classes = {'brkts-popup-sc-game-comment'},
			},
			MatchSummaryWidgets.GameComment{children = game.comment, classes = {'brkts-popup-sc-game-comment'}}
		)
	}
end

---Renders off-factions as Nx2 grid of tiny icons
---@param factions string[]
---@return Html
function StarcraftMatchSummary.OffFactionIcons(factions)
	return HtmlWidgets.Div{
		classes = {'brkts-popup-sc-game-offrace-icons brkts-popup-spaced'},
		children = Array.map(factions, function(faction)
			return Faction.Icon{size = '12px', faction = faction}
		end),
	}
end

---@param submatch StarcraftMatchGroupUtilSubmatch
---@return Widget
function StarcraftMatchSummary.TeamSubmatch(submatch)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			submatch.header and {
				HtmlWidgets.Div{css = {margin = 'auto', ['font-weight'] = 'bold'}, children = {submatch.header}},
				MatchSummaryWidgets.Break{},
			} or nil,
			StarcraftMatchSummary.TeamSubMatchOpponnetRow(submatch),
			Array.map(submatch.games, function(game)
				return StarcraftMatchSummary.Game(
					{noLink = String.startsWith(game.map or '', 'Submatch'), isPartOfSubMatch = true},
					game
				)
			end)
		)
	}
end

---@param submatch StarcraftMatchGroupUtilSubmatch
---@return Widget
function StarcraftMatchSummary.TeamSubMatchOpponnetRow(submatch)
	local opponents = submatch.opponents or {{}, {}}

	local createOpponent = function(opponentIndex)
		local players = (opponents[opponentIndex] or {}).players or {}
		if Logic.isEmpty(players) then
			players = Opponent.tbd(Opponent.solo).players
		end
		return OpponentDisplay.BlockOpponent{
			flip = opponentIndex == 1,
			opponent = {
				players = players,
				type = Opponent.partyTypes[math.max(#players, 1)],
				isArchon = (opponents[opponentIndex] or {}).isArchon,
			},
			showLink = true,
			overflow = 'ellipsis',
		}
	end

	---@param opponentIndex any
	---@return Html
	local createScore = function(opponentIndex)
		return OpponentDisplay.BlockScore{
			isWinner = opponentIndex == submatch.winner or submatch.winner == 0,
			scoreText = DisplayHelper.MapScore(submatch.opponents[opponentIndex], submatch.status),
		}
	end

	return HtmlWidgets.Div{
		classes = {'brkts-popup-header-dev'},
		css = {['justify-content'] = 'center', margin = 'auto'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'brkts-popup-header-opponent', 'brkts-popup-header-opponent-left'},
				children = {
					createOpponent(1),
					createScore(1):addClass('brkts-popup-header-opponent-score-left'),
				},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-header-opponent', 'brkts-popup-header-opponent-right'},
				children = {
					createScore(2):addClass('brkts-popup-header-opponent-score-right'),
					createOpponent(2),
				},
			}
		)
	}
end

---@param veto StarcraftMatchGroupUtilVeto
---@return MatchSummaryRow
function StarcraftMatchSummary.Veto(veto)
	local statusIcon = function(opponentIndex)
		return opponentIndex == veto.by and ICONS.veto or ICONS.noCheck
	end

	local map = veto.map or TBD
	if veto.displayName then
		map = '[[' .. map .. '|' .. veto.displayName .. ']]'
	elseif map:upper() ~= TBD then
		map = '[[' .. map .. ']]'
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = {
			HtmlWidgets.Div{
				classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
				children = {statusIcon(1)},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-sc-veto-center'},
				children = {map},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
				children = {statusIcon(2)},
			}
		},
	}
end

return StarcraftMatchSummary
