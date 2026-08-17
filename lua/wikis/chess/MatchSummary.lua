---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Eco = Lua.import('Module:ChessOpenings')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local Table = Lua.import('Module:Table')

local Collapsible = Lua.import('Module:Widget/Match/Summary/Collapsible')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Span = Html.Span
local Tr = Html.Tr
local Th = Html.Th
local Td = Html.Td
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local KING_ICON_SIZE = '120%'
local KING_ICONS = {
	white = Icon.makeIcon{
		iconName = 'chesskingoutline',
		additionalClasses = {'show-when-light-mode'},
		size = KING_ICON_SIZE,
	} .. Icon.makeIcon{
		iconName = 'chesskingfull',
		additionalClasses = {'show-when-dark-mode'},
		size = KING_ICON_SIZE,
	},
	black = Icon.makeIcon{
		iconName = 'chesskingfull',
		additionalClasses = {'show-when-light-mode'},
		size = KING_ICON_SIZE,
	} .. Icon.makeIcon{
		iconName = 'chesskingoutline',
		additionalClasses = {'show-when-dark-mode'},
		size = KING_ICON_SIZE,
	},
}

---@class ChessCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class ChessMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {}

local ChessMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@param args table
---@return VNode
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return Renderable
function CustomMatchSummary.createGames(match)
	return MatchSummaryWidgets.GamesContainer{
		children = Array.map(match.games, function (game, gameIndex)
			return ChessMatchSummaryGameRow{game = game, gameIndex = gameIndex}
		end)
	}
end

---@param props MatchSummaryGameRowProps
---@return Renderable?
function GameRowComponentProps.createGameOverview(props)
	local game = props.game
	return Div{
		children = {
			Span{
				classes = {'brkts-popup-spaced'},
				children = {
					'Game ' .. props.gameIndex,
					tonumber(game.length) and (' - ' .. game.length .. ' moves') or '',
				},
			},
			Span{
				classes = {'brkts-popup-spaced'},
				children = {Eco.getName(game.extradata.eco, true)},
			},
		},
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	return  Div{
		classes = {'brkts-popup-spaced'},
		---@diagnostic disable-next-line: undefined-field
		children = KING_ICONS[game.opponents[opponentIndex].color],
	}
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createFooter(match)
	local gameLinks = Array.map(match.games, function(game, gameIndex)
		local linksForThisGame = {}
		Table.iter.forEachPair(match.links, function(linkType, link)
			if type(link) ~= 'table' then
				return
			end
			linksForThisGame[linkType] = link[gameIndex]
		end)
		if not game.vod and Logic.isEmpty(linksForThisGame) then
			return
		end

		local vods = MatchSummary.makeVodDisplay(game.vod, {})
		local links = MatchSummary.makeLinksDisplay(linksForThisGame)

		return Tr{children = {
			Td{children = {'Game ', gameIndex}},
			Td{classes = {'brkts-popup-spaced', 'vodlink'}, children = Array.extend(vods, links)}
		}}
	end)

	local matchLinks = {}
	if match.vod then
		matchLinks = Array.extend(matchLinks, MatchSummary.makeVodDisplay(match.vod, {}))
	end
	local rawLinksForMatch = {}
	Table.iter.forEachPair(match.links, function(linkType, link)
		if type(link) ~= 'string' then
			return
		end
		rawLinksForMatch[linkType] = link
	end)

	matchLinks = Array.extend(matchLinks, MatchSummary.makeLinksDisplay(rawLinksForMatch))

	return WidgetUtil.collect(
		Logic.isNotEmpty(gameLinks) and MatchSummaryWidgets.Footer{children = {
			Collapsible{
				tableClasses = {'wikitable-striped'},
				header = Tr{children = {
					Th{css = {width = '20%'}},
					Th{css = {width = '80%'}, children = {'Additional Links'}},
				}},
				children = gameLinks,
			}
		}} or nil,
		Logic.isNotEmpty(matchLinks) and MatchSummaryWidgets.Footer{children = matchLinks} or nil
	)
end

return CustomMatchSummary
