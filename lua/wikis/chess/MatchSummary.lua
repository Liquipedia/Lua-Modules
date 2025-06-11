---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Eco = Lua.import('Module:ChessOpenings')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Collapsible = Lua.import('Module:Widget/Match/Summary/Collapsible')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Tr = HtmlWidgets.Tr
local Th = HtmlWidgets.Th
local Td = HtmlWidgets.Td
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
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
		:css('overflow', 'auto')
		:css('max-height', '70vh')
end

---@param match table
---@param createGame fun(date: string, game: table, gameIndex: integer): Widget
---@return Widget
function CustomMatchSummary.createBody(match, createGame)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, createGame),
		CustomMatchSummary._linksTable(match)
	)}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary.createGame(game, gameIndex)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {padding = '4px'},
		children = WidgetUtil.collect(
			-- Header
			CustomMatchSummary._getHeader(game),

			-- Player 1
			CustomMatchSummary._getSideIcon(game.opponents[1]),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameTeamWrapper{flipped = false},

			-- Center
			MatchSummaryWidgets.GameCenter{
				css = {
					['text-align'] = 'center',
					['align-content'] = 'center',
					['min-height'] = '1.5rem',
					['font-size'] = '85%',
					['line-height'] = '0.75rem',
					['max-width'] = '200px'
				},
				children = CustomMatchSummary._getCenterContent(game, gameIndex),
			},

			-- Player 2
			MatchSummaryWidgets.GameTeamWrapper{flipped = true},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._getSideIcon(game.opponents[2]),

			-- Comment
			MatchSummaryWidgets.GameComment{classes = {'brkts-popup-sc-game-comment'}, children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget
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
				css = {['font-size'] = '85%'},
				children = {Eco.getName(game.extradata.eco, true)},
			},
		},
	}
end

---@param gameOpponent table
---@return Widget
function CustomMatchSummary._getSideIcon(gameOpponent)
	return Div{
		classes = {'brkts-popup-spaced'},
		css = {['padding'] = '0px 4px'},
		children = KING_ICONS[gameOpponent.color],
	}
end

---@param game MatchGroupUtilGame
---@return Widget?
function CustomMatchSummary._getHeader(game)
	return String.isNotEmpty(game.header) and {
		Div{
			children = game.header,
			css = {
				['font-weight'] = 'bold',
				['font-size'] = '85%',
				margin = 'auto'
			}
		},
		MatchSummaryWidgets.Break{}
	} or nil
end

---@param match any
---@return Widget?
function CustomMatchSummary._linksTable(match)
	if Logic.isDeepEmpty(match.links) then
		return
	end

	local rows = Array.map(match.games, function(game, gameIndex)
		local links = Table.mapValues(match.links, function(link)
			if type(link) ~= 'table' then return nil end
			return Table.extract(link, gameIndex)
		end)
		local vod = Table.extract(game, 'vod')
		if not vod and Logic.isDeepEmpty(links) then return end

		local linksFooter = MatchSummary.Footer()
		MatchSummary.addVodsToFooter({vod = vod, games = {}}, linksFooter)
		linksFooter:addLinks(links)

		return Tr{children = {
			Td{children = {'Game ', gameIndex}},
			Td{classes = {'brkts-popup-spaced', 'vodlink'}, children = Array.map(linksFooter.elements, tostring)}
		}}
	end)

	return Collapsible{
		tableClasses = {'wikitable-striped'},
		header = Tr{children = {
			Th{css = {width = '20%'}},
			Th{css = {width = '80%'}, children = {'Additional Links'}},
		}},
		children = rows,
	}
end

return CustomMatchSummary
