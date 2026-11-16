---
-- @Liquipedia
-- page=Module:Widget/Infobox/AgeIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')

---@class AoeAgeIconProps
---@field age string?
---@field checkGame boolean?
---@field game string?

local defaultProps = {
	checkGame = false,
}

---@param props AoeAgeIconProps
---@return string?
local function AoeAgeIcon(props)
	local age = props.age
	if props.checkGame and props.game ~= 'Age of Empires II' or Logic.isEmpty(age) then
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

return Component.component(AoeAgeIcon, defaultProps)
