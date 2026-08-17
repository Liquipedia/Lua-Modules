---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Eco = Lua.import('Module:ChessOpenings')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local String = Lua.import('Module:StringUtils')
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

---@param args table
---@return VNode
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return VNode
function CustomMatchSummary.createGame(date, game, gameIndex)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			-- Header
			CustomMatchSummary._getHeader(game),

			-- Player 1
			MatchSummaryWidgets.GameCenter{
				css = {flex = 1},
				children = {
					CustomMatchSummary._getSideIcon(game.opponents[1]),
					MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
					MatchSummaryWidgets.GameTeamWrapper{flipped = false},
				},
			},

			-- Center
			MatchSummaryWidgets.GameCenter{
				children = CustomMatchSummary._getCenterContent(game, gameIndex),
			},

			-- Player 2
			MatchSummaryWidgets.GameCenter{
				css = {flex = 1},
				children = {
					MatchSummaryWidgets.GameTeamWrapper{flipped = true},
					MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
					CustomMatchSummary._getSideIcon(game.opponents[2]),
				},
			},

			-- Comment
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return VNode
function CustomMatchSummary._getCenterContent(game, gameIndex)
	return Div{
		children = {
			Span{
				classes = {'brkts-popup-spaced'},
				children = {
					'Game ' .. gameIndex,
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

---@param gameOpponent table
---@return VNode
function CustomMatchSummary._getSideIcon(gameOpponent)
	return Div{
		classes = {'brkts-popup-spaced'},
		children = KING_ICONS[gameOpponent.color],
	}
end

---@param game MatchGroupUtilGame
---@return VNode?
function CustomMatchSummary._getHeader(game)
	return String.isNotEmpty(game.header) and {
		Div{
			children = game.header,
			css = {
				['font-weight'] = 'bold',
				margin = 'auto'
			}
		},
		MatchSummaryWidgets.Break{}
	} or nil
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
