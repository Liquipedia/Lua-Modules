---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')

---@class MatchPageHeaderGameItem: Widget
---@operator call(table): MatchPageHeaderGameItem
local MatchPageHeaderGameItem = Class.new(Widget)

---@return string
function MatchPageHeaderGameItem:render()
	if Logic.isEmpty(self.props.name) then
		return ImageIcon{imageLight = 'EmptyIcon itemicon dota2 gameasset.png', size = '64px', caption = 'Empty'}
	end
	return ImageIcon{imageLight = self.props.image, size = '64px', caption = self.props.name}
end

return MatchPageHeaderGameItem
