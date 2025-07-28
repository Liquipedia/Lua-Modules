---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Slash
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchPageSlash: Widget
---@operator call(table): MatchPageSlash
local MatchPageSlash = Class.new(Widget)

---@return Widget
function MatchPageSlash:render()
	return HtmlWidgets.Span{
		classes = {'slash'},
		children = '/'
	}
end

return MatchPageSlash
