---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local MapMode = Lua.import('Module:MapMode')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class AoECustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class AoEMatchSummaryGameRowProps: MatchSummaryGameRowProps
---@field gameData string?
---@field soloMode boolean

---@type Component<AoEMatchSummaryGameRowProps>
local AoEMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(
	{
		createGameOpponentView = CustomMatchSummary.createGameOpponentView,
		createGameOverview = CustomMatchSummary.createGameOverview
	},
	{
		allowWrappingInOverview = true
	}
)

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
---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@param playerIndex integer
---@return {displayName: string?, pageName: string?, flag: string?, civ: string?}
function CustomMatchSummary._getPlayerData(game, opponentIndex, playerIndex)
	return ((game.opponents[opponentIndex] or {}).players or {})[playerIndex] or {}
end

---@private
---@param player table
---@param flipped boolean
---@param gameData string?
---@return Widget
function CustomMatchSummary._createParticipant(player, flipped, gameData)
	local children = {
		CustomMatchSummary._createFactionIcon(player.civ, gameData),
		PlayerDisplay.BlockPlayer{player = player, flip = flipped},
	}
	return HtmlWidgets.Div{
		css = {
			display = 'grid',
			['grid-template-columns'] = 'subgrid',
			['grid-column'] = '1 / -1',
			['align-items'] = 'center',
			['justify-items'] = flipped and 'end' or 'start',
		},
		children = flipped and Array.reverse(children) or children,
	}
end

---@private
---@param game MatchGroupUtilGame
---@param opponentId integer
---@return Widget[]
function CustomMatchSummary._createOpponentDisplay(game, opponentId)
	local flipped = opponentId == 1
	return Array.map(
		Array.sortBy(
			Array.filter(game.opponents[opponentId].players, Table.isNotEmpty),
			Operator.property('index')
		),
		function (player)
			return CustomMatchSummary._createParticipant(player, flipped)
		end
	)
end

---@param props AoEMatchSummaryGameRowProps
---@param opponentIndex integer
---@return table<string, string|number>?
function CustomMatchSummary.getGameOpponentViewCss(props, opponentIndex)
	if props.soloMode then
		return
	end

	local flipped = opponentIndex == 1
	local gridTemplate = {'1fr', 'min-content'}

	return {
		display = 'grid',
		['grid-template-columns'] = table.concat(
			flipped and gridTemplate or Array.reverse(gridTemplate),
			' '
		),
	}
end

---@param props AoEMatchSummaryGameRowProps
---@param opponentIndex integer
---@return Widget|Widget[]
function CustomMatchSummary.createGameOpponentView(props, opponentIndex)
	if props.soloMode then
		return CustomMatchSummary._createFactionIcon(
			CustomMatchSummary._getPlayerData(props.game, opponentIndex, 1).civ, props.gameData
		)
	end

	return CustomMatchSummary._createOpponentDisplay(props.game, opponentIndex)
end

---@param props AoEMatchSummaryGameRowProps
---@return Renderable?
function CustomMatchSummary.createGameOverview(props)
	local game = props.game
	game.mapDisplayName = game.mapDisplayName or game.map

	if game.mapDisplayName and game.extradata and game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end
	return DisplayHelper.MapAndStatus(game)
end

---@private
---@param civ string?
---@param gameData string?
---@return Widget
function CustomMatchSummary._createFactionIcon(civ, gameData)
	local normGame = Game.abbreviation{game = gameData}:lower()
	return HtmlWidgets.Span{
		classes = {'brkts-champion-icon'},
		children = Faction.Icon{
			faction = civ or '',
			game = normGame,
			size = 64,
			showTitle = true,
			showLink = true,
		}
	}
end

return CustomMatchSummary
