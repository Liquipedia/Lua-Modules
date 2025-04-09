---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/Casters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')

local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')

---@class MatchSummaryFfaCasters: Widget
---@operator call(table): MatchSummaryFfaCasters
local MatchSummaryFfaCasters = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaCasters:render()
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

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = {{
		icon = IconWidget{iconName = 'casters', size = '0.875rem'},
		title = 'Caster' .. (#casters > 1 and 's' or '') .. ':',
		content = HtmlWidgets.Span{children = Array.interleave(casters, ', ')},
	}}}
end

return MatchSummaryFfaCasters
