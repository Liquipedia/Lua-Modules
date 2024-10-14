---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Basic/Link
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Fragment = HtmlWidgets.Fragment
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LinkWidgetParameters
---@field children (Widget|Html|string|number)[]
---@field link string
---@field linktype 'internal'|'external'|nil

---@class LinkWidget: Widget
---@operator call(LinkWidgetParameters): LinkWidget
local Link = Class.new(Widget)

---@return Widget
function Link:render()
	if self.props.linktype == 'external' then
		return Fragment{
			children = WidgetUtil.collect(
				'[',
				self.props.link,
				' ',
				unpack(self.props.children),
				']'
			)
		}
	end

	return Fragment{
		children = WidgetUtil.collect(
			'[[',
			self.props.link,
			'|',
			unpack(self.props.children),
			']]'
		)
	}
end

return Link
