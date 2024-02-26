---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Weapon = Lua.import('Module:Infobox/Weapon')

---@class CustomWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	return weapon:createInfobox()
end

return CustomWeapon
