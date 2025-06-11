---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Icon = require('Module:Icon')
local Faction = require('Module:Faction')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ICONS = {
	veto = Icon.makeIcon{iconName = 'veto', color = 'cinnabar-text', size = '110%'},
	noCheck = '[[File:NoCheck.png|link=]]',
}

local UNIFORM_MATCH = 'uniform'
local TBD = 'TBD'
local DEFAULT_HERO = 'default'

local CustomMatchSummary = {}
--local StarcraftMatchSummary = CustomMatchSummary

---@param args {bracketId: string, matchId: string, config: table?}
---@return Html
function CustomMatchSummary.getByMatchId(args)
	-- later when ffa is enabled need to check for that here
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
		:addClass('brkts-popup-sc')
end

---@param match table
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	CustomMatchSummary.computeOfffactions(match)
	local hasHeroes = CustomMatchSummary.hasHeroes(match)
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
		Array.map(match.opponents, CustomMatchSummary.advantageOrPenalty),
		subMatches and Array.map(subMatches, CustomMatchSummary.TeamSubmatch)
			or Array.map(match.games, FnUtil.curry(CustomMatchSummary.Game, {hasHeroes = hasHeroes})),
		Logic.isNotEmpty(match.vetoes) and MatchSummaryWidgets.Row{
			classes = {'brkts-popup-sc-game-header brkts-popup-sc-veto-center'},
			children = {'Vetoes'},
		} or nil,
		Array.map(match.vetoes or {}, CustomMatchSummary.Veto) or nil
	)}
end

---@param match table
function CustomMatchSummary.computeOfffactions(match)
	if match.opponentMode == UNIFORM_MATCH then
		CustomMatchSummary.computeMatchOfffactions(match)
	else
		Array.forEach(match.submatches, CustomMatchSummary.computeMatchOfffactions)
	end
end

---@param match table
function CustomMatchSummary.computeMatchOfffactions(match)
	Array.forEach(match.games, function(game)
		game.offFactions = {}
		Array.forEach(game.opponents, function(gameOpponent, opponentIndex)
			game.offFactions[opponentIndex] = MatchGroupUtil.computeOfffactions(
				gameOpponent,
				match.opponents[opponentIndex]
			)
		end)
	end)
end

---@param match table
---@return boolean
function CustomMatchSummary.hasHeroes(match)
	return Array.any(match.games, function(game)
		return Array.any(game.opponents, function(opponent)
			return Array.any(opponent.players or {}, function(player)
				return Logic.isNotEmpty(player.heroes)
			end)
		end)
	end)
end

---@param opponent StarcraftStandardOpponent
---@return Widget?
function CustomMatchSummary.advantageOrPenalty(opponent)
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

---@param options {hasHeroes: boolean?, isPartOfSubMatch: boolean?}
---@param game table
---@return (Html|string)[]
function CustomMatchSummary.Game(options, game)
	local showOffFactionIcons = game.offFactions ~= nil and (game.offFactions[1] ~= nil or game.offFactions[2] ~= nil)
	local offFactionIcons = function(opponentIndex)
		local offFactions = game.offFactions and game.offFactions[opponentIndex]
		local opponent = game.opponents and game.opponents[opponentIndex]

		return CustomMatchSummary.OffFactionIcons(opponent and offFactions or {})
	end

	local rowWidget = options.isPartOfSubMatch and HtmlWidgets.Div or MatchSummaryWidgets.Row

	return rowWidget{
		classes = {'brkts-popup-body-game', options.isPartOfSubMatch and 'inherit-bg' or nil},
		css = {width = options.isPartOfSubMatch and '100%' or nil},
		children = WidgetUtil.collect(
			game.header and {
				HtmlWidgets.Div{css = {margin = 'auto'}, children = {game.header}},
				MatchSummaryWidgets.Break{},
			} or nil,
			CustomMatchSummary.DisplayHeroes(game.opponents[1], {hasHeroes = options.hasHeroes}),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			showOffFactionIcons and offFactionIcons(1) or nil,
			MatchSummaryWidgets.GameCenter{
				children = DisplayHelper.MapAndStatus(game),
				css = {['flex-grow'] = 1, ['justify-content'] = 'center'}
			},
			showOffFactionIcons and offFactionIcons(2) or nil,
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary.DisplayHeroes(game.opponents[2], {hasHeroes = options.hasHeroes, flipped = true}),
			MatchSummaryWidgets.GameComment{children = game.comment, classes = {'brkts-popup-sc-game-comment'}}
		)
	}
end

---Renders off-factions as Nx2 grid of tiny icons
---@param factions string[]
---@return Html
function CustomMatchSummary.OffFactionIcons(factions)
	local factionsNode = mw.html.create('div')
		:addClass('brkts-popup-sc-game-offrace-icons')
	for _, faction in ipairs(factions) do
		factionsNode:node(Faction.Icon{size = '12px', faction = faction})
	end

	return factionsNode
end

---@param opponent table
---@param options {hasHeroes: boolean?, flipped: boolean?}
---@return Html?
function CustomMatchSummary.DisplayHeroes(opponent, options)
	if not options.hasHeroes then return nil end

	local heroesPerPlayer = Array.map(opponent.players or {}, function(player)
		return Array.map(Array.range(1, 3), function(heroIndex)
			return (player.heroes or {})[heroIndex] or DEFAULT_HERO
		end)
	end)

	return HtmlWidgets.Div{
		classes = {'brkts-popup-body-element-vertical-centered'},
		css = {['flex-direction'] = 'column', ['padding-' .. (options.flipped and 'left' or 'right')] = '8px'},
		children = Array.map(heroesPerPlayer, function(heroes)
			return HtmlWidgets.Div{
				classes = {'brkts-popup-body-element-thumbs', 'brkts-champion-icon'},
				children = MatchSummaryWidgets.Characters{
					flipped = options.flipped,
					characters = heroes,
					bg = 'brkts-popup-side-color-' .. (options.flipped and 'blue' or 'red'),
				},
			}
		end)
	}
end

---@param submatch table
---@return MatchSummaryRow
function CustomMatchSummary.TeamSubmatch(submatch)
	return MatchSummaryWidgets.Row{
		children = WidgetUtil.collect(
			CustomMatchSummary.TeamSubMatchOpponnetRow(submatch),
			CustomMatchSummary.TeamSubMatchGames(submatch)
		)
	}
end

---@param submatch WarcraftMatchGroupUtilSubmatch
---@return Widget
function CustomMatchSummary.TeamSubMatchOpponnetRow(submatch)
	local opponents = submatch.opponents or {{}, {}}

	local createOpponent = function(opponentIndex)
		local players = (opponents[opponentIndex] or {}).players or {}
		if Logic.isEmpty(players) then
			players = Opponent.tbd(Opponent.solo).players
		end
		return OpponentDisplay.BlockOpponent{
			flip = opponentIndex == 1,
			opponent = {players = players, type = Opponent.partyTypes[math.max(#players, 1)]},
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

---@param submatch StarcraftMatchGroupUtilSubmatch
---@return Widget?
function CustomMatchSummary.TeamSubMatchGames(submatch)
	if not CustomMatchSummary._submatchHasDetails(submatch) then return nil end

	return MatchSummaryWidgets.Collapsible{
		classes = {'brkts-popup-header-dev'},
		css = {width = '100%', padding = 0},
		tableClasses = {'inherit-bg'},
		header = HtmlWidgets.Tr{
			children = {
				HtmlWidgets.Th{
					children = {'Submatch Details'},
				},
			},
		},
		children = Array.map(submatch.games, function(game)
			if game.map == 'Submatch Score Fix' then return nil end

			return HtmlWidgets.Tr{
				children = {
					HtmlWidgets.Td{
						children = {CustomMatchSummary.Game({hasHeroes = true, isPartOfSubMatch = true}, game)},
					},
				},
			}
		end)
	}
end

---@param submatch table
---@return boolean
function CustomMatchSummary._submatchHasDetails(submatch)
	return #submatch.games > 0 and Array.any(submatch.games, function(game)
		return String.isNotEmpty(game.map) and game.map:upper() ~= TBD and not string.find(game.map, '^[sS]ubmatch %d+$')
			or Array.any(game.opponents, function(opponent) return Array.any(opponent.players, function(player)
				return Table.isNotEmpty(player.heroes) end) end)
	end)
end

---@param veto StarcraftMatchGroupUtilVeto
---@return MatchSummaryRow
function CustomMatchSummary.Veto(veto)
	local statusIcon = function(opponentIndex)
		return opponentIndex == veto.by and ICONS.veto or ICONS.noCheck
	end

	local map = (veto.map or TBD):upper() == TBD and TBD or ('[[' .. veto.map .. ']]')

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

return CustomMatchSummary
