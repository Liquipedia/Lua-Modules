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
local Title = Class.new(
	Widget,
	function(self)
		-- Legacy support for single string children, convert to array
		-- Widget v2.1 will have this support added to the base class
		if type(self.props.children) == 'string' then
			self.props.children = {self.props.children}
		end
	end
)

---@return string?
function Title:render()
	return HtmlWidgets.Div{children = {HtmlWidgets.Div{
		children = self.props.children,
		classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'}
	}}}
end

return Title
