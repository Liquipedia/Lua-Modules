---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Collapsible
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local TableWidget = Html.Table

---@class MatchSummaryCollapsibleProps
---@field classes string[]?
---@field header Renderable
---@field css table<string, string|number?>?
---@field tableClasses string[]?
---@field tableCss table<string, string|number?>?
---@field children Renderable|Renderable[]?

---@param props MatchSummaryCollapsibleProps
---@return VNode
local function MatchSummaryCollapsible(props)
	assert(props.header, 'No header supplied to MatchSummaryCollapsible Widget')

	return Div{
		classes = Array.extend('brkts-popup-mapveto', props.classes),
		css = Table.mergeInto({width = '100%'}, props.css),
		children = {
			TableWidget{
				classes = Array.extend('collapsible', 'collapsed', props.tableClasses),
				css = props.tableCss,
				children = WidgetUtil.collect(
					props.header,
					props.children
				)
			},
		},
	}
end

return Component.component(MatchSummaryCollapsible)
