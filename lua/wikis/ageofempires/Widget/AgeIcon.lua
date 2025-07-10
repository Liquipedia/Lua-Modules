---
-- @Liquipedia
-- page=Module:Widget/Infobox/AgeIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local Image = Lua.import('Module:Widget/Image/Icon/Image')

---@class AoeAgeIconWidget: Widget
---@operator call(table): AoeAgeIconWidget
---@field props {age: string?, checkGame: boolean, game: string?}
local AoeAgeIcon = Class.new(Widget)
AoeAgeIcon.defaultProps = {
	checkGame = false,
}

---@return Widget?
function AoeAgeIcon:render()
	local age = self.props.age
	if self.props.checkGame and self.props.game ~= 'Age of Empires II' or Logic.isEmpty(age) then
		return
	end

	return Image{
		imageLight = age .. ' Age AoE2 logo.png',
		size = '18',
		link = age .. ' Age'
	}
end

return AoeAgeIcon

