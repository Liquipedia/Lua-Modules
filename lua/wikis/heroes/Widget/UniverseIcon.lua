---
-- @Liquipedia
-- page=Module:Widget/UniverseIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Image = Lua.import('Module:Widget/Image/Icon/Image')

local IMAGE_FILES = {
	diablo = 'Diablo-icon.png',
	starcraft = 'Starcraft-icon.png',
	warcraft = 'Warcraft-icon.png',
	nexus = 'Hots_logo.png',
	overwatch = 'Overwatch logo.png',
	retro = 'OtherFranchise-icon.png',
}
IMAGE_FILES.other = IMAGE_FILES.retro

---@class HeroesUniverseIconProps
---@field universe string?

---@param props HeroesUniverseIconProps
---@return VNode?
local function UniverseIcon(props)
	local file = IMAGE_FILES[(props.universe or ''):lower()]
	if not file then return end
	return Image{
		imageLight = file,
		size = '50x50px',
	}
end

return Component.component(UniverseIcon)
