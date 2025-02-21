---
-- @Liquipedia
-- wiki=chess
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Eco = Lua.import('Module:Chess/ECO')
local FnUtil = Lua.import('Module:FnUtil')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Icon')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

local KING_ICON_SIZE = '150%'
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
		:css('max-height', '50vh')
end

---@param match table
---@param createGame fun(date: string, game: table, gameIndex: integer): Widget
---@return Widget
function CustomMatchSummary.createBody(match, createGame)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		--need the match available in map display instead of just the date so we can access the links
		Array.map(match.games, FnUtil.curry(createGame, match)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game}))
	)}
end

---@param match MatchGroupUtilMatch
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary.createGame(match, game, gameIndex)
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
					['min-height'] = '42px',
					['font-size'] = '85%',
					['line-height'] = '12px',
					['max-width'] = '200px'
				},
				children = CustomMatchSummary._getCenterContent(match, game, gameIndex),
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

---@param match MatchGroupUtilMatch
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget
function CustomMatchSummary._getCenterContent(match, game, gameIndex)
	---@type table<string, string|table|nil>
	local links = Table.mapValues(match.links, function(link)
		if type(link) ~= 'table' then return nil end
		return Table.extract(link, gameIndex)
	end)

	local vod = Table.extract(game, 'vod')

	local linksFooter = MatchSummary.Footer()
	MatchSummary.addVodsToFooter({vod = vod, games = {}}, linksFooter)
	linksFooter:addLinks(links)

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
			Span{
				classes = {'brkts-popup-spaced', 'vodlink'},
				css = {['padding-top'] = '1px'},
				children = Array.map(linksFooter.elements, tostring),
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
---@return Widget
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

return CustomMatchSummary
