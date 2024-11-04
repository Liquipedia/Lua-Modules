---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local MapMode = require('Module:MapMode')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')

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
			opponents = match.opponents,
			game = match.game,
			soloMode = CustomMatchSummary._isSolo(match)
		}):create()
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games,
		MatchSummaryWidgets.Casters{casters = match.extradata.casters}
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
---@param paricipantId string
---@return {displayName: string?, pageName: string?, flag: string?, civ: string?}
function CustomMatchSummary._getPlayerData(game, paricipantId)
	if not game or not game.participants then
		return {}
	end
	return game.participants[paricipantId] or {}
end

---@param game MatchGroupUtilGame
---@param props {game: string?, soloMode: boolean, opponents: standardOpponent[]}
---@return MatchSummaryRow?
function CustomMatchSummary._createGame(game, props)
	if not game.map and not game.winner and String.isEmpty(game.resultType) then return end
	local row = MatchSummary.Row()
		:addClass('brkts-popup-body-game')
		:css('font-size', '0.75rem')
		:css('padding', '4px')
		:css('min-height', '24px')

	local normGame = Game.abbreviation{game = props.game}:lower()
	game.extradata = game.extradata or {}
	game.mapDisplayName = game.mapDisplayName or game.map

	if game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end

	local faction1, faction2

	if props.soloMode then
		faction1 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, '1_1').civ, normGame)
		faction2 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, '2_1').civ, normGame)
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
			local display = mw.html.create('div'):css('display', 'flex'):css('flex-direction', 'column'):css('width', '35%')
			Array.forEach(
				Array.sortBy(game.opponents[opponentId].players, Operator.property('index')),
				function(player)
					display:node(createParticipant(player, opponentId == 1))
				end
			)
			return display
		end

		faction1 = createOpponentDisplay(1)
		faction2 = createOpponentDisplay(2)
	end

	row
			:css('flex-wrap', 'nowrap')
			:addElement(faction1)
			:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
			:addElement(mw.html.create('div')
				:addClass('brkts-popup-spaced'):css('flex-grow', '1')
				:wikitext(DisplayHelper.MapAndStatus(game))
			)
			:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})
			:addElement(faction2)
	return row
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
