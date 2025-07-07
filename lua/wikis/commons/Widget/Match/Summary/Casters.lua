---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Casters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryCasters: Widget
---@operator call(table): MatchSummaryCasters
local MatchSummaryCasters = Class.new(Widget)

---@return Widget?
function MatchSummaryCasters:render()
	if type(self.props.casters) ~= 'table' then
		return nil
	end

	local casters = DisplayHelper.createCastersDisplay(self.props.casters)

	if #casters == 0 then
		return nil
	end

	return HtmlWidgets.Div{
		classes = {'brkts-popup-comment'},
		css = {['white-space'] = 'normal', ['font-size'] = '85%'},
		children = WidgetUtil.collect(
			#casters > 1 and 'Casters: ' or 'Caster: ',
			Array.interleave(casters, ', ')
		),
	}
end

return MatchSummaryCasters
