---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GameDetails
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryFfaGameDetails: Widget
---@operator call(table): MatchSummaryFfaGameDetails
local MatchSummaryFfaGameDetails = Class.new(Widget)

---@return Widget
function MatchSummaryFfaGameDetails:render()
	local game = self.props.game
	assert(game, 'No game provided')

	local casters = game.extradata.casters and DisplayHelper.createCastersDisplay(game.extradata.casters) or nil

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = WidgetUtil.collect(
		{
			icon = CountdownIcon{game = game},
			content = GameCountdown{game = game},
		},
		game.map and {
			icon = IconWidget{iconName = 'map'},
			content = HtmlWidgets.Span{children = Page.makeInternalLink(game.mapDisplayName or game.map, game.map)},
		} or nil,
		Logic.isNotEmpty(casters) and {
			icon = IconWidget{
				iconName = 'casters',
				additionalClasses = {'fa-fw'},
				hover = 'Caster' .. (#casters > 1 and 's' or '')
			},
			content = HtmlWidgets.Span{children = Array.interleave(casters, ', ')},
		} or nil,
		game.comment and {
			icon = IconWidget{iconName = 'comment'},
			content = HtmlWidgets.Span{children = game.comment},
		} or nil
	)}
end

return MatchSummaryFfaGameDetails
