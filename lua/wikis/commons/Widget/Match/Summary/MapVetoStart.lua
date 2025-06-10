---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MapVetoStart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local I18n = require('Module:I18n')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local ARROW_LEFT = IconFa{iconName = 'startleft', size = '110%'}
local ARROW_RIGHT = IconFa{iconName = 'startright', size = '110%'}
local START_MAP_VETO = HtmlWidgets.B{children = I18n.translate('matchsummary-mapveto-start')}

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
			START_MAP_VETO,
			ARROW_LEFT,
			format,
		}
	elseif self.props.firstVeto == 2 then
		children = {
			format,
			ARROW_RIGHT,
			START_MAP_VETO,
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
