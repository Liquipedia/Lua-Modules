---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Weapon = Lua.import('Module:Infobox/Weapon', {requireDevIfEnabled = true})

local CustomWeapon = {}

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	return weapon:createInfobox()
end

return CustomWeapon
