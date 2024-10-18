---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetCenter: WidgetHtmlBase
---@operator call(table): WidgetCenter
local Center = Class.new(WidgetHtml)

---@return Html
function Center:render()
	return self:renderAs('center')
end

return Center
