---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weapon = require('Module:Infobox/Weapon')

local CustomWeapon = {}

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	return weapon:createInfobox(frame)
end

return CustomWeapon
