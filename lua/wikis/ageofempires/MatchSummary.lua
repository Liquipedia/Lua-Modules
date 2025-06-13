---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapMode = require('Module:MapMode')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = require('Module:Player/Display')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {
		width = CustomMatchSummary._determineWidth,
		teamStyle = 'bracket',
	})
end

---@param match MatchGroupUtilMatch
---@return string
function CustomMatchSummary._determineWidth(match)
	return CustomMatchSummary._isSolo(match) and '350px' or '550px'
end

---@param match MatchGroupUtilMatch
---@return Widget
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local games = Array.map(match.games, function(game)
		return CustomMatchSummary._createGame(game, {
			game = match.game,
			soloMode = CustomMatchSummary._isSolo(match)
		})
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games
	)}
end

---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary._isSolo(match)
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.solo and match.opponents[2].type == Opponent.solo
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@param playerIndex integer
---@return {displayName: string?, pageName: string?, flag: string?, civ: string?}
function CustomMatchSummary._getPlayerData(game, opponentIndex, playerIndex)
	return ((game.opponents[opponentIndex] or {}).players or {})[playerIndex] or {}
end

---@param game MatchGroupUtilGame
---@param props {game: string?, soloMode: boolean}
---@return Widget?
function CustomMatchSummary._createGame(game, props)
	if (not game.map) and (not game.winner) and Logic.isEmpty(game.status) and Logic.isDeepEmpty(game.opponents) then
		return
	end

	local normGame = Game.abbreviation{game = props.game}:lower()
	game.mapDisplayName = game.mapDisplayName or game.map

	if game.extradata and game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end

	local faction1, faction2

	if props.soloMode then
		faction1 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, 1, 1).civ, normGame)
		faction2 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, 2, 1).civ, normGame)
	else
		local function createParticipant(player, flipped)
			local playerNode = PlayerDisplay.BlockPlayer{player = player, flip = flipped}
			local factionNode = CustomMatchSummary._createFactionIcon(player.civ, normGame)
			return mw.html.create('div'):css('display', 'flex'):css('align-self', flipped and 'end' or 'start')
				:node(flipped and playerNode or factionNode)
				:wikitext('&nbsp;')
				:node(flipped and factionNode or playerNode)
		end
		local function createOpponentDisplay(opponentId)
			local display = mw.html.create('div')
				:css('display', 'flex')
				:css('width', '90%')
				:css('flex-direction', 'column')
				:css('overflow', 'hidden')
			Array.forEach(
				Array.sortBy(
					Array.filter(game.opponents[opponentId].players, Table.isNotEmpty),
					Operator.property('index')
				),
				function(player)
					display:node(createParticipant(player, opponentId == 1))
				end
			)
			return display
		end

		faction1 = createOpponentDisplay(1)
		faction2 = createOpponentDisplay(2)
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '0.75rem'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = {
					faction1,
					MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1}
				},
			},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.MapAndStatus(game), css = {
					['flex'] = '0 0 30%',
			}},
			MatchSummaryWidgets.GameTeamWrapper{children = {
					faction2,
					MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
				},
				flipped = true
			},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param civ string?
---@param game string
---@return Html
function CustomMatchSummary._createFactionIcon(civ, game)
	return mw.html.create('span')
		:addClass('draft faction')
		:wikitext(Faction.Icon{
			faction = civ or '',
			game = game,
			size = 64,
			showTitle = true,
			showLink = true,
		})
end

return CustomMatchSummary
