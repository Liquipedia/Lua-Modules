---
-- @Liquipedia
-- page=Module:Widget/Infobox/AgeIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')

local Icon = Lua.import('Module:Widget/Image/Icon')

---@class AoeAgeIconWidget: Widget
---@operator call(table): AoeAgeIconWidget
---@field props {age: string?, checkGame: boolean, game: string?}
local AoeAgeIcon = Class.new(Icon)
AoeAgeIcon.defaultProps = {
	checkGame = false,
}

---@return string?
function AoeAgeIcon:render()
	local age = self.props.age
	if self.props.checkGame and self.props.game ~= 'Age of Empires II' or Logic.isEmpty(age) then
		return
	end

	return Image.display(
		age .. ' Age AoE2 logo.png',
		age .. ' Age AoE2 logo.png',
		{
			link = age .. ' Age',
			size = '18',
		}
	)
end

return AoeAgeIcon

