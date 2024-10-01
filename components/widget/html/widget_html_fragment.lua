---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Fragment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetHtmlBase: Widget
---@operator call(table): WidgetHtmlBase
local Fragment = Class.new(WidgetHtml)

---@return Html
function Fragment:make()
	return self:renderAs(nil, self.props.children)
end

return Fragment
