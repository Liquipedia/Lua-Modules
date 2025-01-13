---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')

---@class MatchSummaryFfaHeader: Widget
---@operator call(table): MatchSummaryFfaHeader
local MatchSummaryFfaHeader = Class.new(Widget)

---@return Widget
function MatchSummaryFfaHeader:render()
	assert(self.props.matchId, 'No matchId provided')
	assert(type(self.props.games) == 'table', 'No games provided')

	local function headerItem(title, icon, idx)
		return HtmlWidgets.Li{
			classes = {'panel-tabs__list-item'},
			attributes = {
				['data-js-battle-royale'] = 'panel-tab',
				['data-js-battle-royale-content-target-id'] = self.props.matchId .. 'panel' .. idx,
				role = 'tab',
				tabindex = 0,
			},
			children = {
				icon,
				HtmlWidgets.H4{
					classes = {'panel-tabs__title'},
					children = title,
				},
			},
		}
	end

	local standingsIcon = IconWidget{iconName = 'standings', additionalClasses = {'panel-tabs__list-icon'}}

	return HtmlWidgets.Div{
		classes = {'panel-tabs'},
		attributes = {
			role = 'tabpanel',
		},
		children = HtmlWidgets.Ul{
			classes = {'panel-tabs__list'},
			attributes = {
				role = 'tablist',
			},
			children = WidgetUtil.collect(
				headerItem('Overall standings', standingsIcon, 0),
				Array.map(self.props.games, function (game, idx)
					return headerItem('Game '.. idx, CountdownIcon{game = game, additionalClasses = {'panel-tabs__list-icon'}}, idx)
				end)
			)
		},
	}
end

return MatchSummaryFfaHeader
