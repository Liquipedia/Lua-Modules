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

---@class WidgetHtmlFragment: WidgetHtmlBase
---@operator call(table): WidgetHtmlFragment
local Fragment = Class.new(WidgetHtml)

---@return Html
function Fragment:render()
	return self:renderAs(nil)
end

return Fragment
