---
-- @Liquipedia
-- page=Module:Widget/Infobox/Series/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')
local SeriesIcon = Lua.import('Module:Widget/Infobox/Series/Icon')

---@class InfoboxSeriesDisplayWidget: Widget
---@operator call(table):InfoboxSeriesDisplayWidget
---@field displayManualIcons boolean
---@field series string?
---@field abbreviation string?
---@field icon string?
---@field iconDark string?
---@field iconDisplay string|Widget?
local SeriesDisplay = Class.new(Widget)

---@return Widget?
function SeriesDisplay:render()
	local props = self.props
	if Logic.isEmpty(props.series) then
		return
	end

	local abbreviation = Logic.emptyOr(props.abbreviation, props.series)
	local pageDisplay = Page.makeInternalLink({onlyIfExists = true}, abbreviation, props.series)
		or abbreviation

	local display = Array.append({},
		tostring(self.props.iconDisplay or SeriesIcon(props)),
		pageDisplay
	)
	return HtmlWidgets.Fragment{children = Array.interleave(display, ' ')}
end

return SeriesDisplay
