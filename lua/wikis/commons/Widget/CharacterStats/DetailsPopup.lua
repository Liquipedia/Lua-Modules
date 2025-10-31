---
-- @Liquipedia
-- page=Module:Widget/CharacterStats/DetailsPopup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CharacterStatsDetailsPopup: Widget
---@operator call(table): CharacterStatsDetailsPopup
local CharacterStatsDetailsPopup = Class.new(Widget)

---@return Widget?
function CharacterStatsDetailsPopup:render()
	if Logic.isEmpty(self.props.children) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'character-stats-popup'},
		css = {['z-index'] = 2},
		children = WidgetUtil.collect(
			self:_buildHeader(),
			self.props.children
		)
	}
end

---@private
---@return Widget?
function CharacterStatsDetailsPopup:_buildHeader()
	if Logic.isEmpty(self.props.header) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'character-stats-popup-header'},
		children = self.props.header
	}
end

return CharacterStatsDetailsPopup
