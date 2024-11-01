---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/MapVetoStart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'

---@class MatchSummaryMapVetoStart: Widget
---@operator call(table): MatchSummaryMapVetoStart
local MatchSummaryMapVetoStart = Class.new(Widget)

---@return Widget?
function MatchSummaryMapVetoStart:render()
	if not self.props.firstVeto then
		return
	end

	local format = self.props.vetoFormat and ('Veto Format: ' .. self.props.vetoFormat) or ''
	local children = {}
	if self.props.firstVeto == 1 then
		children = {
			'<b>Start Map Veto</b>',
			ARROW_LEFT,
			format,
		}
	elseif self.props.firstVeto == 2 then
		children = {
			format,
			ARROW_RIGHT,
			'<b>Start Map Veto</b>',
		}
	end

	return HtmlWidgets.Tr{
		classes = {'brkts-popup-mapveto-vetostart'},
		children = Array.map(children, function(child)
			return HtmlWidgets.Th{children = child}
		end)
	}
end

return MatchSummaryMapVetoStart
