---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Abbr
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetAbbr: WidgetHtmlBase
---@operator call(table): WidgetAbbr
local Abbr = Class.new(WidgetHtml)

---@return Html?
function Abbr:render()
	if Logic.isEmpty(self.props.title) or Logic.isEmpty(self.props.children) then
		return nil
	end
	self.props.attributes.title = self.props.attributes.title or self.props.title
	return self:renderAs('abbr')
end

return Abbr
