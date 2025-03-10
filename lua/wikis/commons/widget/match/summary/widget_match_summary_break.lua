---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Break
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchSummaryBreak: Widget
---@operator call(table): MatchSummaryBreak
local MatchSummaryBreak = Class.new(Widget)

---@return Widget
function MatchSummaryBreak:render()
	return Div{
		classes = {'brkts-popup-break'},
	}
end

return MatchSummaryBreak
