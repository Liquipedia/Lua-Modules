---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local MapMode = Lua.import('Module:MapMode')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class AoECustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class AoEMatchSummaryGameRowProps: MatchSummaryGameRowProps
---@field gameData string?
---@field soloMode boolean

---@class AoEMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(AoEMatchSummaryGameRowProps): AoEMatchSummaryGameRow
---@field props AoEMatchSummaryGameRowProps
local AoEMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

---@param args table
---@return Widget
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
	return MatchSummaryWidgets.GamesContainer{
		children = Array.map(match.games, function (game, gameIndex)
			if (not game.map) and (not game.winner) and Logic.isEmpty(game.status) and Logic.isDeepEmpty(game.opponents) then
				return
			end
			return AoEMatchSummaryGameRow{
				game = game,
				gameIndex = gameIndex,
				gameData = match.game,
				soloMode = CustomMatchSummary._isSolo(match)
			}
		end)
	}
end

---@private
---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary._isSolo(match)
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.solo and match.opponents[2].type == Opponent.solo
end

---@private
---@param opponentIndex integer
---@param playerIndex integer
---@return {displayName: string?, pageName: string?, flag: string?, civ: string?}
function AoEMatchSummaryGameRow:_getPlayerData(opponentIndex, playerIndex)
	local game = self.props.game
	return ((game.opponents[opponentIndex] or {}).players or {})[playerIndex] or {}
end

---@private
---@param player table
---@param flipped boolean
---@return Html
function AoEMatchSummaryGameRow:_createParticipant(player, flipped)
	local playerNode = PlayerDisplay.BlockPlayer{player = player, flip = flipped}
	local factionNode = self:_createFactionIcon(player.civ)
	return mw.html.create('div'):css('display', 'flex'):css('align-self', flipped and 'end' or 'start')
		:node(flipped and playerNode or factionNode)
		:wikitext('&nbsp;')
		:node(flipped and factionNode or playerNode)
end

---@private
---@param opponentId integer
---@return Html
function AoEMatchSummaryGameRow:_createOpponentDisplay(opponentId)
	local display = mw.html.create('div')
		:css('display', 'flex')
		:css('width', '90%')
		:css('flex-direction', 'column')
		:css('overflow', 'hidden')
	Array.forEach(
		Array.sortBy(
			Array.filter(self.props.game.opponents[opponentId].players, Table.isNotEmpty),
			Operator.property('index')
		),
		function(player)
			display:node(self:_createParticipant(player, opponentId == 1))
		end
	)
	return display
end

---@param opponentIndex integer
---@return Renderable
function AoEMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	local props = self.props

	if props.soloMode then
		return self:_createFactionIcon(self:_getPlayerData(opponentIndex, 1).civ)
	end

	return self:_createOpponentDisplay(opponentIndex)
end

---@return Renderable?
function AoEMatchSummaryGameRow:createGameOverview()
	local game = self.props.game
	game.mapDisplayName = game.mapDisplayName or game.map

	if game.mapDisplayName and game.extradata and game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end
	return DisplayHelper.MapAndStatus(game)
end

---@private
---@param civ string?
---@return Html
function AoEMatchSummaryGameRow:_createFactionIcon(civ)
	local normGame = Game.abbreviation{game = self.props.gameData}:lower()
	return mw.html.create('span')
		:addClass('draft faction')
		:wikitext(Faction.Icon{
			faction = civ or '',
			game = normGame,
			size = 64,
			showTitle = true,
			showLink = true,
		})
end

return CustomMatchSummary
