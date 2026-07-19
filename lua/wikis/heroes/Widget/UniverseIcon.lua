---
-- @Liquipedia
-- page=Module:Widget/UniverseIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
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

---@class HeroesUniverseIcon: Widget
---@operator call(table): HeroesUniverseIcon
---@field props {universe: string?}
local UniverseIcon = Class.new(Widget)

---@return Widget?
function UniverseIcon:render()
	local file = IMAGE_FILES[(self.props.universe or ''):lower()]
	if not file then return end
	return Image{
		imageLight = file,
		size = '50x50px',
	}
end

return UniverseIcon
