---
-- @Liquipedia
-- page=Module:Widget/Infobox/AoeAgeIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = require('Module:Widget/Html/All')
local Image = require('Module:Widget/Image/Icon/Image')

---@class AoeAgeIconWidget: Widget
---@operator call(table): AoeAgeIconWidget
---@field links table<string, string|number|nil>
local AoeAgeIcon = Class.new(Widget)
AoeAgeIcon.defaultProps = {
	title = 'AoeAgeIcon',
	showTitle = true,
}

---@return Widget
function AoeAgeIcon:render()
	if self.props.checkGame and self.props.game ~= 'Age of Empires II' then
		return HtmlWidgets.Fragment{}
	end

	return Image{
		imageLight = self.props.age .. ' Age AoE2 logo.png',
		size = '18',
		link = self.props.age .. ' Age'
	}
end

return AoeAgeIcon

