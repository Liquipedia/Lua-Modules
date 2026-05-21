---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/ContentItemContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaContentItem
---@field icon Widget?
---@field title string?
---@field content Renderable?

---@class MatchSummaryFfaContentItemContainerProps
---@field collapsed boolean?
---@field collapsible boolean?
---@field contentClass string?
---@field title string?
---@field items MatchSummaryFfaContentItem[]

---@param props MatchSummaryFfaContentItemContainerProps
---@return HtmlNode
local function MatchSummaryFfaContentItem(props)
	local hasContentClass = props.contentClass ~= nil
	local contentContainer = Html.Div{
		classes = {'panel-content__container'},
		attributes = {
			['data-js-battle-royale'] = props.collapsible and 'collapsible-container' or nil,
			role = 'tabpanel',
		},
		children = Html.Ul{
			classes = {props.contentClass},
			children = Array.map(props.items, function(item)
				return Html.Li{
					classes = hasContentClass and {props.contentClass .. '__list-item'} or nil,
					children = {
						Html.Span{
							classes = hasContentClass and {props.contentClass .. '__icon'} or nil,
							children = item.icon,
						},
						Html.Span{
							classes = hasContentClass and {props.contentClass .. '__title'} or nil,
							children = item.title,
						},
						Html.Div{
							classes = hasContentClass and {props.contentClass .. '__container'} or nil,
							children = item.content,
						},
					},
				}
			end),
		}
	}

	if not Logic.readBool(props.collapsible) then
		return contentContainer
	end

	return Html.Div{
		classes = {'panel-content__collapsible', Logic.readBool(props.collapsed) and 'is--collapsed' or nil},
		attributes = {
			['data-js-battle-royale'] = 'collapsible',
		},
		children = {
			Html.H5{
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
					Html.Span{children = props.title},
				}
			},
			contentContainer,
		},
	}
end

return Component.component(MatchSummaryFfaContentItem)
