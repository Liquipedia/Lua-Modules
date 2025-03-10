---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/ContentItemContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaContentItemContainer: Widget
---@operator call(table): MatchSummaryFfaContentItemContainer
local MatchSummaryFfaContentItem = Class.new(Widget)
MatchSummaryFfaContentItem.defaultProps = {
	collapsible = false,
	collapsed = false,
}

---@return Widget
function MatchSummaryFfaContentItem:render()
	local hasContentClass = self.props.contentClass ~= nil
	local contentContainer = HtmlWidgets.Div{
		classes = {'panel-content__container'},
		attributes = {
			['data-js-battle-royale'] = self.props.collapsible and 'collapsible-container' or nil,
			role = 'tabpanel',
		},
		children = HtmlWidgets.Ul{
			classes = {self.props.contentClass},
			children = Array.map(self.props.items, function(item)
				return HtmlWidgets.Li{
					classes = hasContentClass and {self.props.contentClass .. '__list-item'} or nil,
					children = {
						HtmlWidgets.Span{
							classes = hasContentClass and {self.props.contentClass .. '__icon'} or nil,
							children = item.icon,
						},
						HtmlWidgets.Span{
							classes = hasContentClass and {self.props.contentClass .. '__title'} or nil,
							children = item.title,
						},
						HtmlWidgets.Div{
							classes = hasContentClass and {self.props.contentClass .. '__container'} or nil,
							children = item.content,
						},
					},
				}
			end),
		}
	}

	if not self.props.collapsible then
		return contentContainer
	end

	return HtmlWidgets.Div{
		classes = {'panel-content__collapsible', self.props.collapsed and 'is--collapsed' or nil},
		attributes = {
			['data-js-battle-royale'] = 'collapsible',
		},
		children = {
			HtmlWidgets.H5{
				classes = {'panel-content__button'},
				attributes = {
					['data-js-battle-royale'] = 'collapsible-button',
					tabindex = 0,
				},
				children = {
					IconWidget{
						iconName = 'collapse',
						additionalClasses = {'panel-content__button-icon'},
					},
					HtmlWidgets.Span{children = self.props.title},
				}
			},
			contentContainer,
		},
	}
end

return MatchSummaryFfaContentItem
