---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class TitleWidget: Widget
---@operator call(table): TitleWidget
local Title = Class.new(Widget)

---@return string?
function Title:render()
	return HtmlWidgets.Div{children = {HtmlWidgets.Div{
		children = self.props.children,
		classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'}
	}}}
end

return Title
