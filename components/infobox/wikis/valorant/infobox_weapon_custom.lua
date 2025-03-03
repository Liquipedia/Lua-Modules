---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Title = Widgets.Title

local CREDS_ICON = IconImageWidget{
	imageLight = 'Black_Creds_VALORANT.png',
	imageDark = 'White_Creds_VALORANT.png',
	link = 'Creds',
	size = '10px'
}

---@class ValorantWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	return widgets
end

return CustomWeapon
