---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Ul
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetUl: WidgetHtmlBase
---@operator call(table): WidgetUl
local Ul = Class.new(WidgetHtml)

---@return Html
function Ul:render()
	return self:renderAs('ul')
end

return Ul
