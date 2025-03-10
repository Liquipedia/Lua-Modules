---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Casters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryCasters: Widget
---@operator call(table): MatchSummaryCasters
local MatchSummaryCasters = Class.new(Widget)

---@return Widget?
function MatchSummaryCasters:render()
	if type(self.props.casters) ~= 'table' then
		return nil
	end

	local casters = Array.map(self.props.casters, function(caster)
		if not caster.name then
			return nil
		end

		local casterLink = Link{children = caster.displayName, link = caster.name}
		if not caster.flag then
			return casterLink
		end

		return HtmlWidgets.Fragment{children = {
			Flags.Icon(caster.flag),
			'&nbsp;',
			casterLink,
		}}
	end)

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
