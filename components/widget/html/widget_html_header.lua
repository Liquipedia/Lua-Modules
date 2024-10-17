---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetHeader: WidgetHtmlBase
---@operator call(table): WidgetHeader
local Header = Class.new(WidgetHtml)

---@return Html
function Header:render()
	if not self.props.level then
		error('Header level not provided')
	end
	return self:renderAs('h' .. self.props.level)
end

return Header
